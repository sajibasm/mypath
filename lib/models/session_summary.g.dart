// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionSummaryAdapter extends TypeAdapter<SessionSummary> {
  @override
  final int typeId = 1;

  @override
  SessionSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionSummary(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      pointCount: fields[2] as int,
      wheelchairId: fields[6] as int,
      serverSessionId: fields[3] as String?,
      isPendingUpload: fields[4] as bool,
      isPartialUpload: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SessionSummary obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.pointCount)
      ..writeByte(3)
      ..write(obj.serverSessionId)
      ..writeByte(4)
      ..write(obj.isPendingUpload)
      ..writeByte(5)
      ..write(obj.isPartialUpload)
      ..writeByte(6)
      ..write(obj.wheelchairId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
