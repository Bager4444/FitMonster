// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepDataAdapter extends TypeAdapter<RepData> {
  @override
  final int typeId = 11;

  @override
  RepData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepData(
      repNumber: fields[0] as int,
      formScore: fields[1] as double?,
      timestamp: fields[2] as DateTime,
      isCorrect: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RepData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.repNumber)
      ..writeByte(1)
      ..write(obj.formScore)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isCorrect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 13;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String,
      userId: fields[1] as String,
      exerciseId: fields[2] as String,
      exerciseName: fields[3] as String,
      startTime: fields[4] as DateTime,
      endTime: fields[5] as DateTime?,
      targetReps: fields[6] as int,
      repsData: (fields[7] as List).cast<RepData>(),
      status: fields[8] as WorkoutStatus,
      caloriesBurned: fields[9] as int,
      mistakes: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.exerciseName)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.targetReps)
      ..writeByte(7)
      ..write(obj.repsData)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.caloriesBurned)
      ..writeByte(10)
      ..write(obj.mistakes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutStatusAdapter extends TypeAdapter<WorkoutStatus> {
  @override
  final int typeId = 12;

  @override
  WorkoutStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutStatus.notStarted;
      case 1:
        return WorkoutStatus.inProgress;
      case 2:
        return WorkoutStatus.paused;
      case 3:
        return WorkoutStatus.completed;
      case 4:
        return WorkoutStatus.cancelled;
      case 5:
        return WorkoutStatus.failed;
      default:
        return WorkoutStatus.notStarted;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutStatus obj) {
    switch (obj) {
      case WorkoutStatus.notStarted:
        writer.writeByte(0);
        break;
      case WorkoutStatus.inProgress:
        writer.writeByte(1);
        break;
      case WorkoutStatus.paused:
        writer.writeByte(2);
        break;
      case WorkoutStatus.completed:
        writer.writeByte(3);
        break;
      case WorkoutStatus.cancelled:
        writer.writeByte(4);
        break;
      case WorkoutStatus.failed:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
