use pcap::{Capture, Device};
use etherparse::PacketHeaders;
use std::sync::{Arc, Mutex};
use std::collections::HashMap;
use crate::models::NetworkMetrics;

pub struct NidsEngine {
    pub metrics: Arc<Mutex<NetworkMetrics>>,
}

impl NidsEngine {
    pub fn new() -> Self {
        Self {
            metrics: Arc::new(Mutex::new(NetworkMetrics {
                pps: 0,
                bps: 0,
                protocols: HashMap::new(),
            })),
        }
    }

    pub fn start(&self) {
        let metrics_clone = self.metrics.clone();
        std::thread::spawn(move || {
            let device = Device::lookup().expect("No device found").expect("Error looking up device");
            println!("NIDS: Capturing on device: {}", device.name);

            let mut cap = Capture::from_device(device)
                .unwrap()
                .promisc(true)
                .snaplen(5000)
                .open()
                .unwrap();

            let mut packet_count = 0;
            let mut byte_count = 0;
            let mut protocol_stats: HashMap<String, u64> = HashMap::new();
            let mut last_tick = std::time::Instant::now();

            while let Ok(packet) = cap.next_packet() {
                packet_count += 1;
                byte_count += packet.header.len as u64;

                if let Ok(value) = PacketHeaders::from_ethernet_slice(&packet.data) {
                    let proto = if value.net.is_some() {
                        match value.transport {
                            Some(etherparse::TransportHeader::Tcp(_)) => "TCP",
                            Some(etherparse::TransportHeader::Udp(_)) => "UDP",
                            Some(etherparse::TransportHeader::Icmpv4(_)) | Some(etherparse::TransportHeader::Icmpv6(_)) => "ICMP",
                            _ => "Other IP",
                        }
                    } else {
                        "Non-IP"
                    };
                    *protocol_stats.entry(proto.to_string()).or_insert(0) += 1;
                }

                if last_tick.elapsed().as_secs() >= 1 {
                    let mut m = metrics_clone.lock().unwrap();
                    m.pps = packet_count;
                    m.bps = byte_count * 8; // bits per second
                    m.protocols = protocol_stats.clone();

                    // Reset for next second
                    packet_count = 0;
                    byte_count = 0;
                    protocol_stats.clear();
                    last_tick = std::time::Instant::now();
                }
            }
        });
    }
}
