mod models;
mod network;
mod host;

use std::env;

use crate::models::{PrismData, Alert, AlertSeverity};
use crate::network::NidsEngine;
use crate::host::{HidsEngine, FimEngine, AuthLogEngine};

use futures_util::{SinkExt, StreamExt};
use tokio::net::TcpListener;
use tokio::sync::broadcast;
use tokio_tungstenite::accept_async;
use chrono::Local;
use std::fs;

#[tokio::main]
async fn main() {
    println!("Prism Engine starting...");

    // Parse command-line arguments for watch path
    let args: Vec<String> = env::args().collect();
    let watch_path = if args.len() > 1 {
        args[1].clone() // Use the first argument as the watch path
    } else {
        "../prism_watch".to_string() // Default path
    };

    println!("Watching directory: {}", watch_path);

    // Create watch directory if it doesn't exist
    if let Err(e) = fs::create_dir_all(&watch_path) {
        println!("Warning: Could not create watch directory {}: {}", watch_path, e);
    }

    // 1. Initialize Engines
    let nids = NidsEngine::new();
    let hids = HidsEngine::new();

    // 2. Setup Broadcast Channel for WebSocket clients
    let (tx, _rx) = broadcast::channel::<PrismData>(100);
    let tx_clone = tx.clone();
    
    let fim = FimEngine::new(tx.clone());
    let auth_log = AuthLogEngine::new(tx.clone());

    nids.start();
    hids.start();
    fim.start(watch_path.to_string());
    auth_log.start();

    // 3. Background Task: Collect Metrics and Detect Alerts
    let nids_metrics = nids.metrics.clone();
    let hids_metrics = hids.metrics.clone();

    tokio::spawn(async move {
        loop {
            tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;

            let n_metrics = nids_metrics.lock().unwrap().clone();
            let h_metrics = hids_metrics.lock().unwrap().clone();

            // Check for Alerts
            if n_metrics.pps > 5000 {
                let alert = Alert {
                    timestamp: Local::now().format("%Y-%m-%d %H:%M:%S").to_string(),
                    severity: AlertSeverity::High,
                    source: "NIDS".to_string(),
                    message: format!("Potential SYN Flood detected! PPS: {}", n_metrics.pps),
                };
                let _ = tx_clone.send(PrismData::Alert(alert));
            }

            if h_metrics.cpu_usage > 90.0 {
                let alert = Alert {
                    timestamp: Local::now().format("%Y-%m-%d %H:%M:%S").to_string(),
                    severity: AlertSeverity::Medium,
                    source: "HIDS".to_string(),
                    message: format!("Critical CPU usage detected: {:.2}%", h_metrics.cpu_usage),
                };
                let _ = tx_clone.send(PrismData::Alert(alert));
            }

            // Send standard metrics
            let data = PrismData::Metrics {
                network: n_metrics,
                host: h_metrics,
            };
            let _ = tx_clone.send(data);
        }
    });

    // 4. WebSocket Server
    let addr = "127.0.0.1:9002";
    let listener = TcpListener::bind(addr).await.expect("Failed to bind to address");
    println!("WebSocket Server listening on: ws://{}", addr);

    while let Ok((stream, _)) = listener.accept().await {
        let tx = tx.clone();
        tokio::spawn(async move {
            let ws_stream = accept_async(stream).await.expect("Error during the websocket handshake");
            println!("New WebSocket connection established");

            let (mut ws_sender, mut _ws_receiver) = ws_stream.split();
            let mut rx = tx.subscribe();

            while let Ok(data) = rx.recv().await {
                let json = serde_json::to_string(&data).unwrap();
                if ws_sender.send(tokio_tungstenite::tungstenite::Message::Text(json.into())).await.is_err() {
                    break;
                }
            }
            println!("WebSocket connection closed");
        });
    }
}
