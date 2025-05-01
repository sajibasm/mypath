import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  void initialize() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = results.any((result) => result != ConnectivityResult.none);
      _connectionStatusController.add(isConnected);
    });
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
