// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      email: fields[1] as String,
      username: fields[2] as String,
      firstName: fields[3] as String?,
      lastName: fields[4] as String?,
      dateOfBirth: fields[5] as DateTime?,
      gender: fields[6] as String?,
      height: fields[7] as double?,
      weight: fields[8] as double?,
      fitnessLevel: fields[9] as String?,
      fitnessGoals: (fields[10] as List?)?.cast<String>(),
      profileImagePath: fields[11] as String?,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      isActive: fields[14] as bool,
      preferences: (fields[15] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.firstName)
      ..writeByte(4)
      ..write(obj.lastName)
      ..writeByte(5)
      ..write(obj.dateOfBirth)
      ..writeByte(6)
      ..write(obj.gender)
      ..writeByte(7)
      ..write(obj.height)
      ..writeByte(8)
      ..write(obj.weight)
      ..writeByte(9)
      ..write(obj.fitnessLevel)
      ..writeByte(10)
      ..write(obj.fitnessGoals)
      ..writeByte(11)
      ..write(obj.profileImagePath)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.preferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
