// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodItemAdapter extends TypeAdapter<FoodItem> {
  @override
  final int typeId = 5;

  @override
  FoodItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodItem(
      id: fields[0] as String,
      name: fields[1] as String,
      nameRu: fields[2] as String,
      calories: fields[3] as double,
      protein: fields[4] as double,
      fat: fields[5] as double,
      carbs: fields[6] as double,
      category: fields[7] as FoodCategory,
      brand: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nameRu)
      ..writeByte(3)
      ..write(obj.calories)
      ..writeByte(4)
      ..write(obj.protein)
      ..writeByte(5)
      ..write(obj.fat)
      ..writeByte(6)
      ..write(obj.carbs)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.brand);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodCategoryAdapter extends TypeAdapter<FoodCategory> {
  @override
  final int typeId = 6;

  @override
  FoodCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FoodCategory.fruits;
      case 1:
        return FoodCategory.vegetables;
      case 2:
        return FoodCategory.grains;
      case 3:
        return FoodCategory.protein;
      case 4:
        return FoodCategory.dairy;
      case 5:
        return FoodCategory.fats;
      case 6:
        return FoodCategory.sweets;
      case 7:
        return FoodCategory.beverages;
      case 8:
        return FoodCategory.other;
      default:
        return FoodCategory.fruits;
    }
  }

  @override
  void write(BinaryWriter writer, FoodCategory obj) {
    switch (obj) {
      case FoodCategory.fruits:
        writer.writeByte(0);
        break;
      case FoodCategory.vegetables:
        writer.writeByte(1);
        break;
      case FoodCategory.grains:
        writer.writeByte(2);
        break;
      case FoodCategory.protein:
        writer.writeByte(3);
        break;
      case FoodCategory.dairy:
        writer.writeByte(4);
        break;
      case FoodCategory.fats:
        writer.writeByte(5);
        break;
      case FoodCategory.sweets:
        writer.writeByte(6);
        break;
      case FoodCategory.beverages:
        writer.writeByte(7);
        break;
      case FoodCategory.other:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
