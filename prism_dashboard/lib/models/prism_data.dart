import 'dart:convert';

class NetworkMetrics {
  final int pps;
  final int bps;
  final Map<String, int> protocols;

  NetworkMetrics({required this.pps, required this.bps, required this.protocols});

  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkMetrics(
      pps: json['pps'] as int,
      bps: json['bps'] as int,
      protocols: Map<String, int>.from(json['protocols'] as Map),
    );
  }
}

class HostMetrics {
  final double cpuUsage;
  final int memoryUsage;
  final List<ProcessInfo> topProcesses;

  HostMetrics({required this.cpuUsage, required this.memoryUsage, required this.topProcesses});

  factory HostMetrics.fromJson(Map<String, dynamic> json) {
    return HostMetrics(
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      memoryUsage: json['memory_usage'] as int,
      topProcesses: (json['top_processes'] as List)
          .map((e) => ProcessInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProcessInfo {
  final int pid;
  final String name;
  final double cpuUsage;
  final int memoryUsage;

  ProcessInfo({required this.pid, required this.name, required this.cpuUsage, required this.memoryUsage});

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      pid: json['pid'] as int,
      name: json['name'] as String,
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      memoryUsage: json['memory_usage'] as int,
    );
  }
}

enum AlertSeverity { low, medium, high }

enum AlertStatus { unresolved, resolved }

class Alert {
  final String timestamp;
  final AlertSeverity severity;
  final String source;
  final String message;
  final AlertStatus status;

  Alert({
    required this.timestamp,
    required this.severity,
    required this.source,
    required this.message,
    this.status = AlertStatus.unresolved,
  });

  Alert copyWith({
    String? timestamp,
    AlertSeverity? severity,
    String? source,
    String? message,
    AlertStatus? status,
  }) {
    return Alert(
      timestamp: timestamp ?? this.timestamp,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      message: message ?? this.message,
      status: status ?? this.status,
    );
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      timestamp: json['timestamp'] as String,
      severity: _parseSeverity(json['severity'] as String),
      source: json['source'] as String,
      message: json['message'] as String,
      status: AlertStatus.unresolved,
    );
  }

  static AlertSeverity _parseSeverity(String s) {
    switch (s.toLowerCase()) {
      case 'high': return AlertSeverity.high;
      case 'medium': return AlertSeverity.medium;
      case 'low':
      default: return AlertSeverity.low;
    }
  }
}

class PrismUpdate {
  final NetworkMetrics? network;
  final HostMetrics? host;
  final Alert? alert;

  PrismUpdate({this.network, this.host, this.alert});

  factory PrismUpdate.fromJson(String jsonStr) {
    final Map<String, dynamic> json = jsonDecode(jsonStr);
    final type = json['type'] as String;
    final data = json['data'] as Map<String, dynamic>;

    if (type == 'Metrics') {
      return PrismUpdate(
        network: NetworkMetrics.fromJson(data['network'] as Map<String, dynamic>),
        host: HostMetrics.fromJson(data['host'] as Map<String, dynamic>),
      );
    } else if (type == 'Alert') {
      return PrismUpdate(
        alert: Alert.fromJson(data),
      );
    }
    throw Exception('Unknown update type: $type');
  }
}
