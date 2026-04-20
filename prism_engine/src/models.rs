use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NetworkMetrics {
    pub pps: u64,
    pub bps: u64,
    pub protocols: HashMap<String, u64>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct HostMetrics {
    pub cpu_usage: f32,
    pub memory_usage: u64,
    pub top_processes: Vec<ProcessInfo>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ProcessInfo {
    pub pid: u32,
    pub name: String,
    pub cpu_usage: f32,
    pub memory_usage: u64,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum AlertSeverity {
    Low,
    Medium,
    High,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Alert {
    pub timestamp: String,
    pub severity: AlertSeverity,
    pub source: String, // "NIDS" or "HIDS"
    pub message: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(tag = "type", content = "data")]
pub enum PrismData {
    Metrics {
        network: NetworkMetrics,
        host: HostMetrics,
    },
    #[serde(rename = "Alert")]
    Alert(Alert),
}
