use sysinfo::System;
use std::sync::{Arc, Mutex};
use crate::models::{HostMetrics, ProcessInfo};

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
