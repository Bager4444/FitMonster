import 'package:flutter_test/flutter_test.dart';
import 'package:fitmonster/features/exercises/data/exercises_database.dart';

void main() {
  group('ExercisesDatabase', () {
    test('должна содержать 30 упражнений', () {
      final exercises = ExercisesDatabase.getAllExercises();
      expect(exercises.length, 30);
    });

    test('все упражнения должны иметь уникальные ID', () {
      final exercises = ExercisesDatabase.getAllExercises();
      final ids = exercises.map((e) => e.id).toSet();
      expect(ids.length, exercises.length);
    });

    test('должна находить упражнения по ID', () {
      final squats = ExercisesDatabase.getExerciseById('squats');
      expect(squats, isNotNull);
      expect(squats!.nameRu, 'Приседания');

      final jumpingJacks = ExercisesDatabase.getExerciseById('jumping_jacks');
      expect(jumpingJacks, isNotNull);
      expect(jumpingJacks!.nameRu, 'Джампинг Джекс');
    });

    test('должна возвращать null для несуществующего ID', () {
      final exercise = ExercisesDatabase.getExerciseById('nonexistent');
      expect(exercise, isNull);
    });
  });
}