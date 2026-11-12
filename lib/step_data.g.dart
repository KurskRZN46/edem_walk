// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StepDataAdapter extends TypeAdapter<StepData> {
  @override
  final int typeId = 0;

  @override
  StepData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StepData(
      date: fields[0] as DateTime,
      steps: fields[1] as int,
      goal: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StepData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.steps)
      ..writeByte(2)
      ..write(obj.goal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
