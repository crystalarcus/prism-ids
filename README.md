# Prism IDS

Prism is a high-performance Hybrid Intrusion Detection System (IDS) designed for both network and host-based monitoring. It combines a powerful Rust-based analysis engine with a modern Flutter dashboard for real-time visualization and alerting.

## Features

- **Network IDS (NIDS):** Real-time packet capture and protocol analysis (TCP/UDP/ICMP).
- **Host IDS (HIDS):** System health monitoring, process tracking, and file integrity checks.
- **Real-time Visualization:** Live traffic graphs and system metrics via a Flutter desktop GUI.
- **Alerting System:** Threshold-based alerts for suspicious activities (e.g., SYN floods, high resource usage).
- **Cross-Platform:** Built with Rust and Flutter to support Linux and Windows.

## Architecture

- **`prism_engine` (Rust):** The core analysis service. It runs with elevated privileges to capture network traffic and monitor system resources. It streams data over WebSockets to the dashboard.
- **`prism_dashboard` (Flutter):** The graphical user interface. It connects to the engine to provide a user-friendly view of the system's security posture.

## Prerequisites

- **Rust:** `rustup default stable`
- **Flutter:** Stable channel (Desktop support enabled)
- **System Libraries:**
  - Linux: `libpcap`, `pkg-config`
  - Windows: `Npcap` (SDK)

## Getting Started

### 1. Start the Engine (Rust)
```bash
cd prism_engine
cargo run
```
*Note: Network capture may require `sudo` on Linux.*

### 2. Launch the Dashboard (Flutter)
```bash
cd prism_dashboard
flutter run -d linux # or windows
```

## License
MIT
