import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/features/diet/domain/services/calorie_calculator.dart';
import 'package:fitmonster/features/diet/domain/models/user_profile.dart';

void main() {
  group('CalorieCalculator Tests', () {
    late UserProfile maleProfile;
    late UserProfile femaleProfile;

    setUp(() {
      maleProfile = UserProfile(
        userId: 'test_male',
        age: 30,
        height: 180, // см
        weight: 80, // кг
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      femaleProfile = UserProfile(
        userId: 'test_female',
        age: 25,
        height: 165, // см
        weight: 60, // кг
        gender: Gender.female,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('calculateBMR - мужчина', () {
      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      final bmr = CalorieCalculator.calculateBMR(maleProfile);
      expect(bmr, equals(1780.0));
    });

    test('calculateBMR - женщина', () {
      // BMR = 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
      final bmr = CalorieCalculator.calculateBMR(femaleProfile);
      expect(bmr, equals(1345.25));
    });

    test('calculateTDEE - умеренная активность', () {
      // TDEE = BMR * 1.55
      final tdee = CalorieCalculator.calculateTDEE(maleProfile);
      expect(tdee, equals(1780.0 * 1.55));
    });

    test('calculateTargetCalories - поддержание веса', () {
      // Цель поддержание = TDEE * 1.0
      final target = CalorieCalculator.calculateTargetCalories(maleProfile);
      final expectedTdee = 1780.0 * 1.55;
      expect(target, equals(expectedTdee.round()));
    });

    test('calculateTargetCalories - похудение', () {
      final loseProfile = maleProfile.copyWith(goal: Goal.lose);
      final target = CalorieCalculator.calculateTargetCalories(loseProfile);
      final expectedTdee = 1780.0 * 1.55 * 0.85; // -15%
      expect(target, equals(expectedTdee.round()));
    });

    test('calculateMacros - правильное распределение БЖУ', () {
      final macros = CalorieCalculator.calculateMacros(maleProfile);
      final targetCalories = CalorieCalculator.calculateTargetCalories(maleProfile);
      
      // Проверяем распределение
      expect(macros.calories, equals(targetCalories));
      
      // Белки: 30% калорий / 4 ккал/г
      final expectedProtein = (targetCalories * 0.30 / 4).round();
      expect(macros.protein, equals(expectedProtein));
      
      // Жиры: 30% калорий / 9 ккал/г
      final expectedFat = (targetCalories * 0.30 / 9).round();
      expect(macros.fat, equals(expectedFat));
      
      // Углеводы: 40% калорий / 4 ккал/г
      final expectedCarbs = (targetCalories * 0.40 / 4).round();
      expect(macros.carbs, equals(expectedCarbs));
    });

    test('calculateBMI - нормальный вес', () {
      // BMI = 80 / (1.8^2) = 80 / 3.24 = 24.69
      final bmi = CalorieCalculator.calculateBMI(80, 180);
      expect(bmi, closeTo(24.69, 0.01));
    });

    test('getBMICategory - категории', () {
      expect(CalorieCalculator.getBMICategory(17), equals(BMICategory.underweight));
      expect(CalorieCalculator.getBMICategory(22), equals(BMICategory.normal));
      expect(CalorieCalculator.getBMICategory(27), equals(BMICategory.overweight));
      expect(CalorieCalculator.getBMICategory(32), equals(BMICategory.obese));
    });

    test('calculateWeeksToGoal - время достижения цели', () {
      // Разница 10 кг, безопасный темп 0.5 кг/неделю = 20 недель
      final weeks = CalorieCalculator.calculateWeeksToGoal(maleProfile, 70);
      expect(weeks, equals(20));
    });
  });
}