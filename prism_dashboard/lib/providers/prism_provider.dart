import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/prism_data.dart';

class PrismProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  NetworkMetrics? latestNetwork;
  HostMetrics? latestHost;
  List<Alert> alerts = [];
  bool isConnected = false;
  ThemeMode _themeMode = ThemeMode.system;
  bool _showGrid = true;

  ThemeMode get themeMode => _themeMode;
  bool get showGrid => _showGrid;

  final List<int> ppsHistory = [];
  final List<double> cpuHistory = [];

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setShowGrid(bool value) {
    _showGrid = value;
    notifyListeners();
  }

  void connect() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:9002'),
      );
      isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (data) {
          _handleUpdate(data);
        },
        onError: (error) {
          isConnected = false;
          notifyListeners();
          _reconnect();
        },
        onDone: () {
          isConnected = false;
          notifyListeners();
          _reconnect();
        },
      );
    } catch (e) {
      isConnected = false;
      notifyListeners();
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!isConnected) connect();
    });
  }

  void updateAlertStatus(Alert alert, AlertStatus status) {
    final index = alerts.indexOf(alert);
    if (index != -1) {
      alerts[index] = alert.copyWith(status: status);
      notifyListeners();
    }
  }

  void _handleUpdate(String data) {
    try {
      final update = PrismUpdate.fromJson(data);
      if (update.network != null) {
        latestNetwork = update.network;
        ppsHistory.add(latestNetwork!.pps);
        if (ppsHistory.length > 60) ppsHistory.removeAt(0);
      }
      if (update.host != null) {
        latestHost = update.host;
        cpuHistory.add(latestHost!.cpuUsage);
        if (cpuHistory.length > 60) cpuHistory.removeAt(0);
      }
      if (update.alert != null) {
        alerts.insert(0, update.alert!);
        if (alerts.length > 100) alerts.removeLast();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing update: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
