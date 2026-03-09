// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StayPointAdapter extends TypeAdapter<StayPoint> {
  @override
  final int typeId = 2;

  @override
  StayPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StayPoint(
      id: fields[0] as String,
      centroidLat: fields[1] as double,
      centroidLon: fields[2] as double,
      arrivalTime: fields[3] as DateTime,
      departureTime: fields[4] as DateTime,
      dwellDurationMinutes: fields[5] as int,
      label: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StayPoint obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.centroidLat)
      ..writeByte(2)
      ..write(obj.centroidLon)
      ..writeByte(3)
      ..write(obj.arrivalTime)
      ..writeByte(4)
      ..write(obj.departureTime)
      ..writeByte(5)
      ..write(obj.dwellDurationMinutes)
      ..writeByte(6)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StayPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
