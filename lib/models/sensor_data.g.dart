// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorDataAdapter extends TypeAdapter<SensorData> {
  @override
  final int typeId = 0;

  @override
  SensorData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorData(
      timestamp: fields[0] as DateTime,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      accX: fields[3] as double,
      accY: fields[4] as double,
      accZ: fields[5] as double,
      gyroX: fields[6] as double,
      gyroY: fields[7] as double,
      gyroZ: fields[8] as double,
      magX: fields[9] as double,
      magY: fields[10] as double,
      magZ: fields[11] as double,
      sessionId: fields[13] as String,
      pressure: fields[12] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, SensorData obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.accX)
      ..writeByte(4)
      ..write(obj.accY)
      ..writeByte(5)
      ..write(obj.accZ)
      ..writeByte(6)
      ..write(obj.gyroX)
      ..writeByte(7)
      ..write(obj.gyroY)
      ..writeByte(8)
      ..write(obj.gyroZ)
      ..writeByte(9)
      ..write(obj.magX)
      ..writeByte(10)
      ..write(obj.magY)
      ..writeByte(11)
      ..write(obj.magZ)
      ..writeByte(12)
      ..write(obj.pressure)
      ..writeByte(13)
      ..write(obj.sessionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
