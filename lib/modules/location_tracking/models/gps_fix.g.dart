// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_fix.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GpsFixAdapter extends TypeAdapter<GpsFix> {
  @override
  final int typeId = 1;

  @override
  GpsFix read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GpsFix(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      accuracy: fields[2] as double,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GpsFix obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.accuracy)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpsFixAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
