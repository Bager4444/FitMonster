import 'package:flutter/material.dart';

/// Утилитарный класс для цветовой категоризации упражнений
class ExerciseColors {
  /// Определяет категорию упражнения для цветовой схемы
  static String getCategoryForExercise(String exerciseId) {
    switch (exerciseId) {
      // Силовые упражнения
      case 'squats':
      case 'pushups':
      case 'lunges':
      case 'jump_squats':
      case 'reverse_lunges':
      case 'knee_pushups':
      case 'side_plank':
      case 'calf_raises':
      case 'superman':
      case 'glute_bridge':
      case 'sumo_squats':
      case 'plank_leg_lifts':
      case 'lateral_lunges':
      case 'single_leg_deadlift':
      case 'sit_ups':
      case 'tricep_dips':
      case 'wall_sit':
        return 'Силовые';
      
      // Кардио упражнения
      case 'jumping_jacks':
      case 'burpees':
      case 'mountain_climbers':
      case 'high_knees':
      case 'jump_rope':
      case 'running_in_place':
      case 'burpee_pushup':
      case 'jump_in_place':
        return 'Кардио';
      
      // Функциональные упражнения (кор, пресс, растяжка)
      case 'plank':
      case 'crunches':
      case 'leg_raises':
      case 'bicycle_crunches':
      case 'reverse_crunches':
      case 'russian_twists':
      case 'downward_dog':
      case 'dead_bug':
      case 'bear_crawl':
        return 'Функциональные';
      
      default:
        return 'Силовые';
    }
  }

  /// Получает цвета для упражнения в зависимости от его типа
  static List<Color> getColorsForExerciseType(String exerciseId) {
    final category = getCategoryForExercise(exerciseId);
    
    switch (category) {
      case 'Силовые':
        // Красно-оранжевые тона для силовых упражнений
        return [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];
      
      case 'Кардио':
        // Сине-зеленые тона для кардио упражнений
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
      
      case 'Функциональные':
        // Фиолетово-синие тона для функциональных упражнений
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      
      default:
        // По умолчанию - розовые тона
        return [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)];
    }
  }

  /// Получает цвета для комплекса в зависимости от его типа
  static List<Color> getColorsForComplexType(List<String> exerciseIds) {
    final type = getComplexType(exerciseIds);
    
    switch (type) {
      case 'Силовые':
        // Красно-оранжевые тона для силовых комплексов
        return [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];
      
      case 'Кардио':
        // Сине-зеленые тона для кардио комплексов
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
      
      case 'Функциональные':
        // Фиолетово-синие тона для функциональных комплексов
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      
      case 'Смешанные':
        // Желто-зеленые тона для смешанных комплексов
        return [const Color(0xFF45B7D1), const Color(0xFF96C93D)];
      
      default:
        // По умолчанию - розовые тона
        return [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)];
    }
  }

  /// Определяет тип комплекса на основе упражнений
  static String getComplexType(List<String> exerciseIds) {
    // Подсчитываем количество упражнений каждого типа
    int strengthCount = 0;
    int cardioCount = 0;
    int functionalCount = 0;
    
    for (final exerciseId in exerciseIds) {
      final category = getCategoryForExercise(exerciseId);
      switch (category) {
        case 'Силовые':
          strengthCount++;
          break;
        case 'Кардио':
          cardioCount++;
          break;
        case 'Функциональные':
          functionalCount++;
          break;
      }
    }
    
    // Определяем преобладающий тип
    if (cardioCount > strengthCount && cardioCount > functionalCount) {
      return 'Кардио';
    } else if (functionalCount > strengthCount && functionalCount > cardioCount) {
      return 'Функциональные';
    } else if (strengthCount == cardioCount && strengthCount > functionalCount) {
      return 'Смешанные';
    } else {
      return 'Силовые';
    }
  }
}