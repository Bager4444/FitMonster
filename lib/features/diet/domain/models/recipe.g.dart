// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 10;

  @override
  Recipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recipe(
      id: fields[0] as String,
      name: fields[1] as String,
      nameRu: fields[2] as String,
      description: fields[3] as String?,
      ingredients: (fields[4] as List).cast<RecipeIngredient>(),
      instructions: (fields[5] as List).cast<String>(),
      prepTimeMinutes: fields[6] as int,
      cookTimeMinutes: fields[7] as int,
      servings: fields[8] as int,
      totalCalories: fields[9] as int,
      totalProtein: fields[10] as double,
      totalFat: fields[11] as double,
      totalCarbs: fields[12] as double,
      imageUrl: fields[13] as String?,
      tags: (fields[14] as List).cast<String>(),
      source: fields[15] as String?,
      sourceUrl: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nameRu)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.ingredients)
      ..writeByte(5)
      ..write(obj.instructions)
      ..writeByte(6)
      ..write(obj.prepTimeMinutes)
      ..writeByte(7)
      ..write(obj.cookTimeMinutes)
      ..writeByte(8)
      ..write(obj.servings)
      ..writeByte(9)
      ..write(obj.totalCalories)
      ..writeByte(10)
      ..write(obj.totalProtein)
      ..writeByte(11)
      ..write(obj.totalFat)
      ..writeByte(12)
      ..write(obj.totalCarbs)
      ..writeByte(13)
      ..write(obj.imageUrl)
      ..writeByte(14)
      ..write(obj.tags)
      ..writeByte(15)
      ..write(obj.source)
      ..writeByte(16)
      ..write(obj.sourceUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecipeIngredientAdapter extends TypeAdapter<RecipeIngredient> {
  @override
  final int typeId = 14;

  @override
  RecipeIngredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeIngredient(
      foodId: fields[0] as String,
      foodName: fields[1] as String,
      amount: fields[2] as double,
      unit: fields[3] as String,
      unitRu: fields[4] as String,
      calories: fields[5] as int,
      protein: fields[6] as double,
      fat: fields[7] as double,
      carbs: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeIngredient obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.foodId)
      ..writeByte(1)
      ..write(obj.foodName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.unitRu)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.fat)
      ..writeByte(8)
      ..write(obj.carbs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
