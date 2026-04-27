use sysinfo::System;
use std::sync::{Arc, Mutex};
use crate::models::{HostMetrics, ProcessInfo, PrismData, Alert, AlertSeverity};
use notify::{Watcher, RecursiveMode, Config};
use std::path::Path;
use tokio::sync::broadcast;
use chrono::Local;
use std::fs::File;
use std::io::{BufRead, BufReader, Seek, SeekFrom};
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

pub struct HidsEngine {
    pub metrics: Arc<Mutex<HostMetrics>>,
}

impl HidsEngine {
    pub fn new() -> Self {
        Self {
            metrics: Arc::new(Mutex::new(HostMetrics {
                cpu_usage: 0.0,
                memory_usage: 0,
                top_processes: Vec::new(),
            })),
        }
    }

    pub fn start(&self) {
        let metrics_clone = self.metrics.clone();
        std::thread::spawn(move || {
            let mut sys = System::new_all();
            
            loop {
                sys.refresh_all();

                let mut top_processes: Vec<ProcessInfo> = sys.processes()
                    .values()
                    .map(|p| ProcessInfo {
                        pid: p.pid().as_u32(),
                        name: p.name().to_string_lossy().to_string(),
                        cpu_usage: p.cpu_usage(),
                        memory_usage: p.memory(),
                    })
                    .collect();

                // Sort by CPU usage descending and take top 5
                top_processes.sort_by(|a, b| b.cpu_usage.partial_cmp(&a.cpu_usage).unwrap());
                top_processes.truncate(5);

                let mut m = metrics_clone.lock().unwrap();
                m.cpu_usage = sys.global_cpu_usage();
                m.memory_usage = sys.used_memory();
                m.top_processes = top_processes;

                std::thread::sleep(std::time::Duration::from_secs(1));
            }
        });
    }
}

pub struct FimEngine {
    pub tx: broadcast::Sender<PrismData>,
}

impl FimEngine {
    pub fn new(tx: broadcast::Sender<PrismData>) -> Self {
        Self { tx }
    }

    pub fn start(&self, path_to_watch: String) {
        let tx = self.tx.clone();
        std::thread::spawn(move || {
            let (event_tx, event_rx) = std::sync::mpsc::channel();

            let mut watcher = notify::RecommendedWatcher::new(event_tx, Config::default()).unwrap();
            
            if let Err(e) = watcher.watch(Path::new(&path_to_watch), RecursiveMode::Recursive) {
                println!("FIM Error: Could not watch path {}: {:?}", path_to_watch, e);
                return;
            }

            println!("FIM: Watching path: {}", path_to_watch);

            for res in event_rx {
                match res {
                    Ok(event) => {
                        // Filter out access events (too noisy)
                        if event.kind.is_modify() || event.kind.is_create() || event.kind.is_remove() {
                            let paths: Vec<String> = event.paths.iter()
                                .map(|p| p.to_string_lossy().into_owned())
                                .collect();
                            
                            let msg = format!("File changed: {:?} | Path: {:?}", event.kind, paths);
                            let alert = Alert {
                                timestamp: Local::now().format("%Y-%m-%d %H:%M:%S").to_string(),
                                severity: AlertSeverity::High,
                                source: "FIM".to_string(),
                                message: msg,
                            };
                            let _ = tx.send(PrismData::Alert(alert));
                        }
                    }
                    Err(e) => println!("FIM Watch error: {:?}", e),
                }
            }
        });
    }
}

pub struct AuthLogEngine {
    pub tx: broadcast::Sender<PrismData>,
}

impl AuthLogEngine {
    pub fn new(tx: broadcast::Sender<PrismData>) -> Self {
        Self { tx }
    }

    pub fn start(&self) {
        let tx = self.tx.clone();
        thread::spawn(move || {
            let log_paths = ["/var/log/auth.log", "/var/log/secure"];
            let mut file = None;
            let mut path_used = "";

            for path in log_paths {
                if let Ok(f) = File::open(path) {
                    file = Some(f);
                    path_used = path;
                    break;
                }
            }

            if let Some(mut file) = file {
                println!("AuthLogEngine: Monitoring file {}", path_used);
                // Seek to the end to only monitor new events
                let _ = file.seek(SeekFrom::End(0));
                let mut reader = BufReader::new(file);
                let mut line = String::new();
                let mut failure_count = 0;

                loop {
                    match reader.read_line(&mut line) {
                        Ok(0) => { thread::sleep(Duration::from_millis(500)); }
                        Ok(_) => {
                            Self::process_line(&line, &mut failure_count, &tx);
                            line.clear();
                        }
                        Err(e) => {
                            println!("AuthLogEngine Error reading log: {:?}", e);
                            thread::sleep(Duration::from_secs(1));
                        }
                    }
                }
            } else {
                println!("AuthLogEngine: No log files found, falling back to journalctl...");
                // Fallback to journalctl -f for Arch Linux and other systemd distros
                let child = Command::new("journalctl")
                    .args(["-f", "-n", "0", "-t", "sudo", "-t", "auth", "-t", "systemd-logind", "-t", "sshd"])
                    .stdout(Stdio::piped())
                    .spawn();

                match child {
                    Ok(mut child) => {
                        let stdout = child.stdout.take().expect("Failed to open journalctl stdout");
                        let mut reader = BufReader::new(stdout);
                        let mut line = String::new();
                        let mut failure_count = 0;

                        loop {
                            match reader.read_line(&mut line) {
                                Ok(0) => break, // Process exited
                                Ok(_) => {
                                    Self::process_line(&line, &mut failure_count, &tx);
                                    line.clear();
                                }
                                Err(_) => break,
                            }
                        }
                    }
                    Err(e) => {
                        println!("AuthLogEngine: Failed to spawn journalctl: {:?}", e);
                    }
                }
            }
        });
    }

    fn process_line(line: &str, failure_count: &mut i32, tx: &broadcast::Sender<PrismData>) {
        let lower_line = line.to_lowercase();
        let mut alert_msg = None;
        let mut severity = AlertSeverity::Medium;

        if lower_line.contains("sudo") && lower_line.contains("user not in sudoers") {
            alert_msg = Some(format!("Unauthorized sudo attempt: {}", line.trim()));
            severity = AlertSeverity::High;
        } else if lower_line.contains("sudo") && lower_line.contains("incorrect password") {
            *failure_count += 1;
            alert_msg = Some(format!("Failed sudo attempt (incorrect password): {}", line.trim()));
        } else if lower_line.contains("authentication failure") || lower_line.contains("failed login") || lower_line.contains("failed password") {
            *failure_count += 1;
            alert_msg = Some(format!("Failed login attempt: {}", line.trim()));
        } else {
            if lower_line.contains("session opened") || lower_line.contains("accepted password") {
                *failure_count = 0;
            }
        }

        if *failure_count >= 3 {
            let alert = Alert {
                timestamp: Local::now().format("%Y-%m-%d %H:%M:%S").to_string(),
                severity: AlertSeverity::High,
                source: "HIDS".to_string(),
                message: format!("Brute force detected! {} consecutive failures.", failure_count),
            };
            let _ = tx.send(PrismData::Alert(alert));
            *failure_count = 0; 
        }

        if let Some(msg) = alert_msg {
            let alert = Alert {
                timestamp: Local::now().format("%Y-%m-%d %H:%M:%S").to_string(),
                severity,
                source: "HIDS".to_string(),
                message: msg,
            };
            let _ = tx.send(PrismData::Alert(alert));
        }
    }
}
