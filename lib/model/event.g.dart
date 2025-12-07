// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 5;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String,
      image: fields[3] as String,
      date: fields[4] as String,
      time: fields[5] as String,
      location: fields[6] as String,
      status: fields[7] as String,
      registrationStatus: fields[8] as String,
      registrationUrl: fields[9] as String,
      isNew: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.image)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.time)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.registrationStatus)
      ..writeByte(9)
      ..write(obj.registrationUrl)
      ..writeByte(10)
      ..write(obj.isNew);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
