abstract class LocationServiceBase {
  Stream<dynamic> get locationStream;
  Future<dynamic> getCurrentLocation();
}

abstract class SensorDataServiceBase {
  Future<void> start();
  Function(dynamic data)? onData;
  void stop();
}
