import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/features/exercises/services/improved_rep_counter.dart';

void main() {
  group('ImprovedRepCounter', () {
    late ImprovedRepCounter counter;

    setUp(() {
      counter = ImprovedRepCounter();
    });

    test('должен инициализироваться с нулевым счетчиком', () {
      expect(counter.repCount, 0);
      expect(counter.isInDownPosition, false);
    });

    test('должен сбрасывать счетчик', () {
      counter.reset();
      expect(counter.repCount, 0);
      expect(counter.isInDownPosition, false);
    });

    test('должен устанавливать тип упражнения', () {
      expect(() => counter.setExerciseType('squats'), returnsNormally);
      expect(() => counter.setExerciseType('pushups'), returnsNormally);
      expect(() => counter.setExerciseType('lunges'), returnsNormally);
    });

    test('должен поддерживать все новые упражнения', () {
      final supportedExercises = [
        'squats', 'pushups', 'lunges', 'crunches', 'burpees',
        'leg_raises', 'jump_rope', 'running_in_place',
        'jumping_jacks', 'mountain_climbers', 'high_knees',
        'jump_squats', 'reverse_lunges', 'knee_pushups',
        'side_plank', 'calf_raises', 'superman', 'glute_bridge',
        'bicycle_crunches', 'sumo_squats', 'plank_leg_lifts',
        'reverse_crunches', 'burpee_pushup', 'lateral_lunges',
        'russian_twists', 'single_leg_deadlift', 'jump_in_place', 'sit_ups'
      ];

      for (final exercise in supportedExercises) {
        expect(() => counter.setExerciseType(exercise), returnsNormally);
      }
    });
  });
}
