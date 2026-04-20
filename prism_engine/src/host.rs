use sysinfo::System;
use std::sync::{Arc, Mutex};
use crate::models::{HostMetrics, ProcessInfo, PrismData, Alert, AlertSeverity};
use notify::{Watcher, RecursiveMode, Config};
use std::path::Path;
use tokio::sync::broadcast;
use chrono::Local;

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
