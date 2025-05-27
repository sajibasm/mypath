import 'package:flutter/foundation.dart';

import 'FakeLocationService.dart';
import 'FakeSensorDataService.dart';
import 'RealLocationService.dart';
import 'SensorDataService.dart';


class DevModeEnvironment {
  static bool get isDebug => false; // or use const bool kUseFake = true;
  
  static dynamic getLocationService() {
    print("Using ${isDebug ? 'Fake' : 'Real'} Location Service");
    
    return isDebug ? FakeLocationService() : RealLocationService();
  }

  static SensorDataService getSensorService() {
    print("Using ${isDebug ? 'Fake' : 'Real'} Sensor Data Service");
    return isDebug ? FakeSensorDataService() : SensorDataService();
  }
}
