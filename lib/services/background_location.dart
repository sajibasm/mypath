import 'package:background_locator_2/location_dto.dart';
import 'package:hive/hive.dart';

Future<void> callback(LocationDto locationDto) async {
  final box = await Hive.openBox('sensorDataBox');
  final now = DateTime.now().millisecondsSinceEpoch;

  box.put(now.toString(), {
    'time_stamp': now,
    'lat': locationDto.latitude,
    'lng': locationDto.longitude,
    'ax': 0.0, // Placeholders (you can update these live too if you want)
    'ay': 0.0,
    'az': 0.0,
    'gx': 0.0,
    'gy': 0.0,
    'gz': 0.0,
    'mx': 0.0,
    'my': 0.0,
    'mz': 0.0,
  });
}

void initCallback() {
  print('BackgroundLocator INIT');
}

void disposeCallback() {
  print('BackgroundLocator DISPOSE');
}

void notificationCallback() {
  print('BackgroundLocator Notification clicked');
}
