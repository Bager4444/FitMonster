import 'package:fitmonster/features/exercises/domain/models/exercise.dart';

/// База данных упражнений
class ExercisesDatabase {
  static final List<Exercise> _exercises = [
    // 1. Приседания
    Exercise(
      id: 'squats',
      nameRu: 'Приседания',
      nameEn: 'Squats',
      description:
          'Базовое упражнение для ног и ягодиц. Укрепляет квадрицепсы, бицепсы бедра и ягодичные мышцы.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Ноги', 'Ягодицы', 'Кор'],
      caloriesPerMinute: 8,
      instructions: [
        'Встаньте прямо, ноги на ширине плеч',
        'Руки вытяните перед собой или скрестите на груди',
        'Опуститесь вниз, сгибая колени и отводя таз назад',
        'Опускайтесь до параллели бедер с полом',
        'Вернитесь в исходное положение, отталкиваясь пятками',
      ],
      commonMistakes: [
        'Колени выходят за носки',
        'Спина округляется',
        'Пятки отрываются от пола',
        'Недостаточная глубина приседа',
      ],
    ),

    // 2. Отжимания
    Exercise(
      id: 'pushups',
      nameRu: 'Отжимания',
      nameEn: 'Push-ups',
      description:
          'Классическое упражнение для верхней части тела. Развивает грудные мышцы, трицепсы и плечи.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Грудь', 'Трицепсы', 'Плечи', 'Кор'],
      caloriesPerMinute: 7,
      instructions: [
        'Примите упор лежа, руки на ширине плеч',
        'Тело должно образовывать прямую линию',
        'Опуститесь вниз, сгибая локти',
        'Грудь почти касается пола',
        'Вернитесь в исходное положение, выпрямляя руки',
      ],
      commonMistakes: [
        'Провисание поясницы',
        'Поднятие таза вверх',
        'Локти слишком широко разведены',
        'Неполная амплитуда движения',
      ],
    ),

    // 3. Планка
    Exercise(
      id: 'plank',
      nameRu: 'Планка',
      nameEn: 'Plank',
      description:
          'Статическое упражнение для укрепления кора. Развивает выносливость мышц пресса и спины.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Кор', 'Пресс', 'Спина', 'Плечи'],
      caloriesPerMinute: 5,
      instructions: [
        'Примите упор на предплечья и носки',
        'Локти под плечами',
        'Тело образует прямую линию от головы до пяток',
        'Напрягите пресс и ягодицы',
        'Держите позицию, дышите ровно',
      ],
      commonMistakes: [
        'Провисание поясницы',
        'Поднятие таза вверх',
        'Задержка дыхания',
        'Опущенная голова',
      ],
    ),

    // 4. Подъем ног лежа
    Exercise(
      id: 'leg_raises',
      nameRu: 'Подъем ног лежа',
      nameEn: 'Leg Raises',
      description:
          'Упражнение для нижней части пресса. Укрепляет прямую мышцу живота и сгибатели бедра.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Пресс', 'Сгибатели бедра'],
      caloriesPerMinute: 6,
      instructions: [
        'Лягте на спину, руки вдоль тела или под ягодицами',
        'Ноги прямые, вместе',
        'Поднимите ноги вверх до угла 90 градусов',
        'Медленно опустите ноги, не касаясь пола',
        'Повторите движение',
      ],
      commonMistakes: [
        'Отрыв поясницы от пола',
        'Слишком быстрое выполнение',
        'Сгибание ног в коленях',
        'Опускание ног на пол',
      ],
    ),

    // 5. Скручивания
    Exercise(
      id: 'crunches',
      nameRu: 'Скручивания',
      nameEn: 'Crunches',
      description:
          'Базовое упражнение для пресса. Изолированно прорабатывает прямую мышцу живота.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Пресс'],
      caloriesPerMinute: 5,
      instructions: [
        'Лягте на спину, ноги согнуты, стопы на полу',
        'Руки за головой или скрещены на груди',
        'Поднимите плечи и верхнюю часть спины',
        'Напрягите пресс в верхней точке',
        'Медленно вернитесь в исходное положение',
      ],
      commonMistakes: [
        'Тянуть голову руками',
        'Отрыв поясницы от пола',
        'Слишком высокий подъем',
        'Рывковые движения',
      ],
    ),

    // 6. Выпады
    Exercise(
      id: 'lunges',
      nameRu: 'Выпады',
      nameEn: 'Lunges',
      description:
          'Упражнение для ног и ягодиц. Развивает баланс и координацию, укрепляет квадрицепсы.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Ноги', 'Ягодицы', 'Баланс'],
      caloriesPerMinute: 7,
      instructions: [
        'Встаньте прямо, ноги вместе',
        'Сделайте шаг вперед одной ногой',
        'Опуститесь вниз, сгибая оба колена до 90 градусов',
        'Переднее колено над пяткой, заднее почти касается пола',
        'Вернитесь в исходное положение и повторите с другой ногой',
      ],
      commonMistakes: [
        'Переднее колено выходит за носок',
        'Наклон корпуса вперед',
        'Слишком узкий шаг',
        'Потеря баланса',
      ],
    ),

    // 7. Бурпи
    Exercise(
      id: 'burpees',
      nameRu: 'Бурпи',
      nameEn: 'Burpees',
      description:
          'Комплексное кардио-упражнение. Задействует все тело, отлично сжигает калории.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.advanced,
      muscleGroups: ['Все тело', 'Кардио'],
      caloriesPerMinute: 12,
      instructions: [
        'Встаньте прямо',
        'Присядьте и поставьте руки на пол',
        'Прыжком примите упор лежа',
        'Сделайте отжимание (опционально)',
        'Прыжком подтяните ноги к рукам',
        'Выпрыгните вверх с поднятыми руками',
      ],
      commonMistakes: [
        'Провисание в планке',
        'Неполная амплитуда',
        'Слишком быстрое выполнение',
        'Задержка дыхания',
      ],
    ),

    // 8. Прыжки со скакалкой
    Exercise(
      id: 'jump_rope',
      nameRu: 'Прыжки со скакалкой',
      nameEn: 'Jump Rope',
      description:
          'Кардио-упражнение для выносливости. Улучшает координацию и сжигает много калорий.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Икры', 'Кардио', 'Координация'],
      caloriesPerMinute: 13,
      instructions: [
        'Возьмите скакалку, руки по бокам',
        'Вращайте скакалку запястьями',
        'Прыгайте на носках, колени слегка согнуты',
        'Приземляйтесь мягко',
        'Держите ритм и дышите ровно',
      ],
      commonMistakes: [
        'Прыжки на всей стопе',
        'Слишком высокие прыжки',
        'Вращение всей рукой',
        'Неровный ритм',
      ],
    ),

    // 9. Собака мордой вниз
    Exercise(
      id: 'downward_dog',
      nameRu: 'Собака мордой вниз',
      nameEn: 'Downward Dog',
      description:
          'Йога-поза для растяжки и укрепления. Растягивает заднюю поверхность тела.',
      category: ExerciseCategory.flexibility,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Спина', 'Ноги', 'Плечи', 'Растяжка'],
      caloriesPerMinute: 3,
      instructions: [
        'Встаньте на четвереньки',
        'Поднимите таз вверх, выпрямляя ноги',
        'Тело образует треугольник',
        'Пятки тянутся к полу',
        'Голова между руками, взгляд на ноги',
        'Дышите глубоко и ровно',
      ],
      commonMistakes: [
        'Округление спины',
        'Согнутые колени',
        'Плечи у ушей',
        'Задержка дыхания',
      ],
    ),

    // 10. Бег на месте
    Exercise(
      id: 'running_in_place',
      nameRu: 'Бег на месте',
      nameEn: 'Running in Place',
      description:
          'Простое кардио-упражнение. Разогревает тело и улучшает выносливость.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Ноги', 'Кардио'],
      caloriesPerMinute: 10,
      instructions: [
        'Встаньте прямо',
        'Начните бег на месте, поднимая колени',
        'Руки работают в такт ногам',
        'Приземляйтесь на носки',
        'Держите темп и дышите ритмично',
      ],
      commonMistakes: [
        'Слишком низкий подъем коленей',
        'Приземление на пятки',
        'Неподвижные руки',
        'Задержка дыхания',
      ],
    ),

    // 11. Джампинг Джекс
    Exercise(
      id: 'jumping_jacks',
      nameRu: 'Джампинг Джекс',
      nameEn: 'Jumping Jacks',
      description:
          'Динамичное кардио-упражнение. Задействует все тело и улучшает координацию.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Все тело', 'Кардио', 'Координация'],
      caloriesPerMinute: 11,
      instructions: [
        'Встаньте прямо, ноги вместе, руки по бокам',
        'Прыжком разведите ноги на ширину плеч',
        'Одновременно поднимите руки над головой',
        'Прыжком вернитесь в исходное положение',
        'Повторяйте в быстром темпе',
      ],
      commonMistakes: [
        'Неполное разведение ног',
        'Руки не достают до головы',
        'Приземление на пятки',
        'Потеря ритма',
      ],
    ),

    // 12. Горные альпинисты
    Exercise(
      id: 'mountain_climbers',
      nameRu: 'Горные альпинисты',
      nameEn: 'Mountain Climbers',
      description:
          'Интенсивное кардио-упражнение в планке. Укрепляет кор и улучшает выносливость.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Кор', 'Ноги', 'Плечи', 'Кардио'],
      caloriesPerMinute: 12,
      instructions: [
        'Примите упор лежа (планка)',
        'Подтяните правое колено к груди',
        'Быстро смените ноги',
        'Подтяните левое колено к груди',
        'Продолжайте чередовать в быстром темпе',
      ],
      commonMistakes: [
        'Поднятие таза вверх',
        'Слишком медленный темп',
        'Неполное подтягивание коленей',
        'Провисание в планке',
      ],
    ),

    // 13. Высокие колени
    Exercise(
      id: 'high_knees',
      nameRu: 'Высокие колени',
      nameEn: 'High Knees',
      description:
          'Кардио-упражнение для развития скорости и координации. Укрепляет мышцы ног.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Ноги', 'Кор', 'Кардио'],
      caloriesPerMinute: 9,
      instructions: [
        'Встаньте прямо',
        'Поднимайте колени как можно выше',
        'Стремитесь коснуться коленями груди',
        'Руки работают как при беге',
        'Держите быстрый темп',
      ],
      commonMistakes: [
        'Низкий подъем коленей',
        'Наклон корпуса назад',
        'Медленный темп',
        'Неактивные руки',
      ],
    ),

    // 14. Приседания с прыжком
    Exercise(
      id: 'jump_squats',
      nameRu: 'Приседания с прыжком',
      nameEn: 'Jump Squats',
      description:
          'Взрывное упражнение для ног. Развивает силу и мощность нижней части тела.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Ноги', 'Ягодицы', 'Кор'],
      caloriesPerMinute: 10,
      instructions: [
        'Встаньте в позицию для приседаний',
        'Опуститесь в присед',
        'Взрывным движением выпрыгните вверх',
        'Мягко приземлитесь в присед',
        'Сразу переходите к следующему повторению',
      ],
      commonMistakes: [
        'Жесткое приземление',
        'Неполный присед',
        'Колени внутрь при приземлении',
        'Потеря баланса',
      ],
    ),

    // 15. Обратные выпады
    Exercise(
      id: 'reverse_lunges',
      nameRu: 'Обратные выпады',
      nameEn: 'Reverse Lunges',
      description:
          'Вариация выпадов с шагом назад. Меньше нагрузки на колени, больше на ягодицы.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Ноги', 'Ягодицы', 'Баланс'],
      caloriesPerMinute: 7,
      instructions: [
        'Встаньте прямо, ноги вместе',
        'Сделайте шаг назад одной ногой',
        'Опуститесь в выпад',
        'Оттолкнитесь задней ногой и вернитесь',
        'Повторите с другой ногой',
      ],
      commonMistakes: [
        'Слишком короткий шаг',
        'Наклон корпуса вперед',
        'Переднее колено за носком',
        'Потеря равновесия',
      ],
    ),

    // 16. Отжимания с колен
    Exercise(
      id: 'knee_pushups',
      nameRu: 'Отжимания с колен',
      nameEn: 'Knee Push-ups',
      description:
          'Облегченная версия отжиманий. Подходит для начинающих и развития техники.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Грудь', 'Трицепсы', 'Плечи'],
      caloriesPerMinute: 5,
      instructions: [
        'Встаньте на колени и руки',
        'Руки на ширине плеч',
        'Тело прямое от коленей до головы',
        'Опуститесь грудью к полу',
        'Вернитесь в исходное положение',
      ],
      commonMistakes: [
        'Провисание поясницы',
        'Неполная амплитуда',
        'Слишком широкие руки',
        'Быстрое выполнение',
      ],
    ),

    // 17. Боковая планка
    Exercise(
      id: 'side_plank',
      nameRu: 'Боковая планка',
      nameEn: 'Side Plank',
      description:
          'Статическое упражнение для косых мышц живота. Развивает стабильность кора.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Кор', 'Косые мышцы', 'Плечи'],
      caloriesPerMinute: 4,
      instructions: [
        'Лягте на бок',
        'Поднимитесь на предплечье',
        'Тело образует прямую линию',
        'Поднимите таз от пола',
        'Держите позицию, не провисая',
      ],
      commonMistakes: [
        'Провисание таза',
        'Опора на руку сверху',
        'Наклон головы',
        'Неровное дыхание',
      ],
    ),

    // 18. Подъемы на носки
    Exercise(
      id: 'calf_raises',
      nameRu: 'Подъемы на носки',
      nameEn: 'Calf Raises',
      description:
          'Изолированное упражнение для икроножных мышц. Укрепляет голени.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Икры', 'Голени'],
      caloriesPerMinute: 3,
      instructions: [
        'Встаньте прямо, ноги на ширине плеч',
        'Поднимитесь на носки как можно выше',
        'Задержитесь в верхней точке',
        'Медленно опуститесь',
        'Не касайтесь пятками пола',
      ],
      commonMistakes: [
        'Быстрое выполнение',
        'Неполный подъем',
        'Помощь руками',
        'Потеря равновесия',
      ],
    ),

    // 19. Супермен
    Exercise(
      id: 'superman',
      nameRu: 'Супермен',
      nameEn: 'Superman',
      description:
          'Упражнение для укрепления спины. Развивает мышцы-разгибатели позвоночника.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Спина', 'Ягодицы', 'Задняя поверхность бедра'],
      caloriesPerMinute: 4,
      instructions: [
        'Лягте на живот, руки вытянуты вперед',
        'Одновременно поднимите руки и ноги',
        'Прогнитесь в спине',
        'Задержитесь на 2-3 секунды',
        'Медленно опуститесь',
      ],
      commonMistakes: [
        'Слишком высокий подъем',
        'Задержка дыхания',
        'Резкие движения',
        'Напряжение шеи',
      ],
    ),

    // 20. Ягодичный мостик
    Exercise(
      id: 'glute_bridge',
      nameRu: 'Ягодичный мостик',
      nameEn: 'Glute Bridge',
      description:
          'Упражнение для ягодиц и задней поверхности бедра. Улучшает осанку.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Ягодицы', 'Задняя поверхность бедра', 'Кор'],
      caloriesPerMinute: 5,
      instructions: [
        'Лягте на спину, колени согнуты',
        'Стопы на полу, руки по бокам',
        'Поднимите таз вверх',
        'Напрягите ягодицы в верхней точке',
        'Медленно опуститесь',
      ],
      commonMistakes: [
        'Отрыв стоп от пола',
        'Прогиб в пояснице',
        'Слишком быстрое выполнение',
        'Неполное сжатие ягодиц',
      ],
    ),

    // 21. Велосипед (скручивания)
    Exercise(
      id: 'bicycle_crunches',
      nameRu: 'Велосипед',
      nameEn: 'Bicycle Crunches',
      description:
          'Динамичное упражнение для пресса. Прорабатывает прямые и косые мышцы живота.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Пресс', 'Косые мышцы'],
      caloriesPerMinute: 8,
      instructions: [
        'Лягте на спину, руки за головой',
        'Поднимите ноги, согнув в коленях',
        'Подтяните правый локоть к левому колену',
        'Одновременно выпрямите правую ногу',
        'Смените стороны в динамичном темпе',
      ],
      commonMistakes: [
        'Тянуть голову руками',
        'Слишком быстрый темп',
        'Неполное скручивание',
        'Опускание ног на пол',
      ],
    ),

    // 22. Приседания сумо
    Exercise(
      id: 'sumo_squats',
      nameRu: 'Приседания сумо',
      nameEn: 'Sumo Squats',
      description:
          'Широкие приседания с акцентом на внутреннюю поверхность бедра и ягодицы.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Ноги', 'Ягодицы', 'Внутренняя поверхность бедра'],
      caloriesPerMinute: 8,
      instructions: [
        'Встаньте широко, носки развернуты наружу',
        'Руки на поясе или перед собой',
        'Опуститесь в присед, колени в стороны',
        'Спина прямая, вес на пятках',
        'Поднимитесь, сжимая ягодицы',
      ],
      commonMistakes: [
        'Колени заваливаются внутрь',
        'Недостаточно широкая постановка ног',
        'Наклон корпуса вперед',
        'Отрыв пяток от пола',
      ],
    ),

    // 23. Планка с подъемом ног
    Exercise(
      id: 'plank_leg_lifts',
      nameRu: 'Планка с подъемом ног',
      nameEn: 'Plank Leg Lifts',
      description:
          'Усложненная планка с динамическим элементом. Укрепляет кор и ягодицы.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.advanced,
      muscleGroups: ['Кор', 'Ягодицы', 'Плечи', 'Спина'],
      caloriesPerMinute: 7,
      instructions: [
        'Примите позицию планки на предплечьях',
        'Поднимите одну ногу вверх',
        'Держите ногу прямой',
        'Задержитесь на 2-3 секунды',
        'Опустите и смените ногу',
      ],
      commonMistakes: [
        'Поднятие таза при подъеме ноги',
        'Сгибание поднимаемой ноги',
        'Потеря стабильности планки',
        'Слишком высокий подъем ноги',
      ],
    ),

    // 24. Обратные скручивания
    Exercise(
      id: 'reverse_crunches',
      nameRu: 'Обратные скручивания',
      nameEn: 'Reverse Crunches',
      description:
          'Упражнение для нижней части пресса. Подтягивание коленей к груди.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Нижний пресс', 'Кор'],
      caloriesPerMinute: 6,
      instructions: [
        'Лягте на спину, руки вдоль тела',
        'Поднимите ноги, согнув в коленях',
        'Подтяните колени к груди',
        'Слегка оторвите таз от пола',
        'Медленно вернитесь в исходное положение',
      ],
      commonMistakes: [
        'Использование инерции',
        'Слишком быстрое выполнение',
        'Помощь руками',
        'Неполная амплитуда движения',
      ],
    ),

    // 25. Берпи с отжиманием
    Exercise(
      id: 'burpee_pushup',
      nameRu: 'Берпи с отжиманием',
      nameEn: 'Burpee Push-up',
      description:
          'Усложненная версия берпи с добавлением отжимания. Максимальная нагрузка.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.advanced,
      muscleGroups: ['Все тело', 'Кардио'],
      caloriesPerMinute: 15,
      instructions: [
        'Встаньте прямо',
        'Присядьте и поставьте руки на пол',
        'Прыжком примите упор лежа',
        'Сделайте отжимание',
        'Прыжком подтяните ноги к рукам',
        'Выпрыгните вверх с поднятыми руками',
      ],
      commonMistakes: [
        'Пропуск отжимания',
        'Неполная амплитуда отжимания',
        'Провисание в планке',
        'Слишком быстрое выполнение',
      ],
    ),

    // 26. Выпады в сторону
    Exercise(
      id: 'lateral_lunges',
      nameRu: 'Выпады в сторону',
      nameEn: 'Lateral Lunges',
      description:
          'Боковые выпады для проработки внутренней поверхности бедра и ягодиц.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Ноги', 'Ягодицы', 'Внутренняя поверхность бедра'],
      caloriesPerMinute: 7,
      instructions: [
        'Встаньте прямо, ноги вместе',
        'Сделайте широкий шаг в сторону',
        'Согните одну ногу, другую держите прямой',
        'Опуститесь как можно ниже',
        'Оттолкнитесь и вернитесь в центр',
      ],
      commonMistakes: [
        'Недостаточно широкий шаг',
        'Наклон корпуса вперед',
        'Отрыв пятки опорной ноги',
        'Сгибание прямой ноги',
      ],
    ),

    // 27. Русские скручивания
    Exercise(
      id: 'russian_twists',
      nameRu: 'Русские скручивания',
      nameEn: 'Russian Twists',
      description:
          'Вращательные движения корпуса для проработки косых мышц живота.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.intermediate,
      muscleGroups: ['Косые мышцы', 'Кор', 'Пресс'],
      caloriesPerMinute: 6,
      instructions: [
        'Сядьте, слегка отклонив корпус назад',
        'Поднимите ноги или держите на весу',
        'Поворачивайте корпус влево и вправо',
        'Руки можно сцепить или держать перед собой',
        'Держите пресс в напряжении',
      ],
      commonMistakes: [
        'Слишком быстрые повороты',
        'Опускание ног на пол',
        'Округление спины',
        'Поворот только руками',
      ],
    ),

    // 28. Мертвая тяга на одной ноге
    Exercise(
      id: 'single_leg_deadlift',
      nameRu: 'Мертвая тяга на одной ноге',
      nameEn: 'Single Leg Deadlift',
      description:
          'Упражнение на баланс и заднюю поверхность бедра. Развивает стабильность.',
      category: ExerciseCategory.balance,
      difficulty: ExerciseDifficulty.advanced,
      muscleGroups: ['Задняя поверхность бедра', 'Ягодицы', 'Баланс', 'Кор'],
      caloriesPerMinute: 6,
      instructions: [
        'Встаньте на одну ногу',
        'Наклонитесь вперед, отводя свободную ногу назад',
        'Тянитесь руками к полу',
        'Держите спину прямой',
        'Вернитесь в исходное положение',
      ],
      commonMistakes: [
        'Округление спины',
        'Потеря равновесия',
        'Сгибание опорной ноги',
        'Касание свободной ногой пола',
      ],
    ),

    // 29. Прыжки на месте
    Exercise(
      id: 'jump_in_place',
      nameRu: 'Прыжки на месте',
      nameEn: 'Jump in Place',
      description:
          'Простые вертикальные прыжки для развития взрывной силы ног.',
      category: ExerciseCategory.cardio,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Ноги', 'Икры', 'Кардио'],
      caloriesPerMinute: 9,
      instructions: [
        'Встаньте прямо, ноги на ширине плеч',
        'Слегка согните колени',
        'Выпрыгните вверх как можно выше',
        'Мягко приземлитесь на носки',
        'Сразу переходите к следующему прыжку',
      ],
      commonMistakes: [
        'Жесткое приземление на пятки',
        'Слишком широкая постановка ног',
        'Неполное выпрямление в прыжке',
        'Потеря ритма',
      ],
    ),

    // 30. Подъемы корпуса
    Exercise(
      id: 'sit_ups',
      nameRu: 'Подъемы корпуса',
      nameEn: 'Sit-ups',
      description:
          'Классическое упражнение для пресса с полным подъемом корпуса.',
      category: ExerciseCategory.strength,
      difficulty: ExerciseDifficulty.beginner,
      muscleGroups: ['Пресс', 'Сгибатели бедра'],
      caloriesPerMinute: 6,
      instructions: [
        'Лягте на спину, колени согнуты',
        'Руки за головой или скрещены на груди',
        'Поднимите весь корпус к коленям',
        'Коснитесь локтями коленей',
        'Медленно опуститесь обратно',
      ],
      commonMistakes: [
        'Тянуть голову руками',
        'Слишком быстрое выполнение',
        'Отрыв стоп от пола',
        'Неполный подъем корпуса',
      ],
    ),
  ];

  /// Получить все упражнения
  static List<Exercise> getAllExercises() {
    return List.unmodifiable(_exercises);
  }

  /// Получить упражнение по ID
  static Exercise? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить упражнения по категории
  static List<Exercise> getExercisesByCategory(ExerciseCategory category) {
    return _exercises
        .where((exercise) => exercise.category == category)
        .toList();
  }

  /// Получить упражнения по сложности
  static List<Exercise> getExercisesByDifficulty(
      ExerciseDifficulty difficulty) {
    return _exercises
        .where((exercise) => exercise.difficulty == difficulty)
        .toList();
  }

  /// Поиск упражнений
  static List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return getAllExercises();

    final lowerQuery = query.toLowerCase();
    return _exercises.where((exercise) {
      return exercise.nameRu.toLowerCase().contains(lowerQuery) ||
          exercise.nameEn.toLowerCase().contains(lowerQuery) ||
          exercise.description.toLowerCase().contains(lowerQuery) ||
          exercise.muscleGroups
              .any((muscle) => muscle.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Получить рекомендованные упражнения для начинающих
  static List<Exercise> getBeginnerExercises() {
    return getExercisesByDifficulty(ExerciseDifficulty.beginner);
  }
}
