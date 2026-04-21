# Prism IDS

Prism is a high-performance Hybrid Intrusion Detection System (IDS) designed for both network and host-based monitoring. It combines a powerful Rust-based analysis engine with a modern Flutter dashboard for real-time visualization and alerting.

## Features

- **Network IDS (NIDS):** Real-time packet capture and protocol analysis (TCP/UDP/ICMP).
- **Host IDS (HIDS):** System health monitoring, process tracking, and **File Integrity Monitoring (FIM)**.
- **Real-time Visualization:** Live traffic graphs and system metrics via a Flutter desktop GUI.
- **Alerting System:** Threshold-based alerts and real-time notifications for unauthorized file changes.

## File Integrity Monitoring (HIDS/FIM)

The engine can monitor a specified directory for file integrity changes.

### 1. Start the Engine (Rust)

**Usage with default watch directory:**
The engine will create and watch a `./prism_watch` directory in the project root by default.
```bash
cd prism_engine
cargo run
```
*Note: Network capture may require `sudo` on Linux.*

**Usage with custom watch directory:**
You can configure the engine to watch a different directory by providing the path as a command-line argument when running the executable.

```bash
# After building the engine (e.g., with 'cargo build')
cd prism_engine/target/debug # or target/release
./prism_engine /path/to/your/custom/watch/folder
```
Replace `/path/to/your/custom/watch/folder` with the actual directory you want the engine to monitor. If no argument is provided, it will default to watching `./prism_watch`.

## Architecture

- **`prism_engine` (Rust):** The core analysis service. It runs with elevated privileges to capture network traffic, monitor system resources, and watch for file changes. It streams data over WebSockets to the dashboard.
- **`prism_dashboard` (Flutter):** The graphical user interface. It connects to the engine to provide a user-friendly view of the system's security posture.

## Prerequisites

- **Rust:** `rustup default stable`
- **Flutter:** Stable channel (Desktop support enabled)
- **System Libraries:**
  - Linux: `libpcap`, `pkg-config`
  - Windows: `Npcap` (SDK)

## Getting Started

### 2. Launch the Dashboard (Flutter)
```bash
cd prism_dashboard
flutter run -d linux # or windows
```

## License
MIT
