/// База данных аллергенов и противопоказаний
class AllergensDatabase {
  /// Популярные аллергены
  static const List<String> commonAllergens = [
    'Молоко и молочные продукты',
    'Яйца',
    'Рыба',
    'Морепродукты (креветки, крабы)',
    'Орехи (арахис, миндаль, грецкие)',
    'Соя',
    'Пшеница (глютен)',
    'Кунжут',
    'Мед',
    'Цитрусовые',
    'Клубника',
    'Шоколад',
    'Помидоры',
    'Грибы',
  ];

  /// Популярные противопоказания
  static const List<String> commonContraindications = [
    'Диабет',
    'Гипертония (высокое давление)',
    'Гастрит',
    'Язва желудка',
    'Панкреатит',
    'Холецистит',
    'Подагра',
    'Заболевания почек',
    'Заболевания печени',
    'Непереносимость лактозы',
    'Целиакия (непереносимость глютена)',
    'Беременность',
    'Грудное вскармливание',
  ];

  /// Проверка продукта на аллергены
  static bool hasAllergen(String foodName, List<String> userAllergies) {
    final lowerFoodName = foodName.toLowerCase();
    
    for (final allergen in userAllergies) {
      final lowerAllergen = allergen.toLowerCase();
      
      // Молоко
      if (lowerAllergen.contains('молок') && 
          (lowerFoodName.contains('молок') || 
           lowerFoodName.contains('сыр') || 
           lowerFoodName.contains('творог') ||
           lowerFoodName.contains('йогурт') ||
           lowerFoodName.contains('кефир'))) {
        return true;
      }
      
      // Яйца
      if (lowerAllergen.contains('яйц') && lowerFoodName.contains('яйц')) {
        return true;
      }
      
      // Рыба
      if (lowerAllergen.contains('рыб') && lowerFoodName.contains('рыб')) {
        return true;
      }
      
      // Морепродукты
      if (lowerAllergen.contains('морепродукт') && 
          (lowerFoodName.contains('креветк') || 
           lowerFoodName.contains('краб') ||
           lowerFoodName.contains('кальмар'))) {
        return true;
      }
      
      // Орехи
      if (lowerAllergen.contains('орех') && 
          (lowerFoodName.contains('орех') || 
           lowerFoodName.contains('арахис') ||
           lowerFoodName.contains('миндаль'))) {
        return true;
      }
      
      // Глютен/пшеница
      if (lowerAllergen.contains('пшениц') || lowerAllergen.contains('глютен')) {
        if (lowerFoodName.contains('хлеб') || 
            lowerFoodName.contains('макарон') ||
            lowerFoodName.contains('пшениц') ||
            lowerFoodName.contains('мука')) {
          return true;
        }
      }
      
      // Прямое совпадение
      if (lowerFoodName.contains(lowerAllergen) || 
          lowerAllergen.contains(lowerFoodName)) {
        return true;
      }
    }
    
    return false;
  }

  /// Получить предупреждение для противопоказания
  static String? getWarningForContraindication(
    String foodName, 
    List<String> contraindications,
  ) {
    final lowerFoodName = foodName.toLowerCase();
    
    for (final condition in contraindications) {
      final lowerCondition = condition.toLowerCase();
      
      // Диабет - сахар
      if (lowerCondition.contains('диабет')) {
        if (lowerFoodName.contains('сахар') || 
            lowerFoodName.contains('конфет') ||
            lowerFoodName.contains('торт') ||
            lowerFoodName.contains('печень')) {
          return '⚠️ Осторожно при диабете - высокое содержание сахара';
        }
      }
      
      // Гипертония - соль
      if (lowerCondition.contains('гипертон') || lowerCondition.contains('давлен')) {
        if (lowerFoodName.contains('соленый') || 
            lowerFoodName.contains('колбас') ||
            lowerFoodName.contains('сосиск')) {
          return '⚠️ Осторожно при гипертонии - высокое содержание соли';
        }
      }
      
      // Гастрит/язва - острое
      if (lowerCondition.contains('гастрит') || lowerCondition.contains('язв')) {
        if (lowerFoodName.contains('острый') || 
            lowerFoodName.contains('перец') ||
            lowerFoodName.contains('чеснок')) {
          return '⚠️ Не рекомендуется при гастрите/язве';
        }
      }
      
      // Подагра - мясо
      if (lowerCondition.contains('подагр')) {
        if (lowerFoodName.contains('мясо') || 
            lowerFoodName.contains('печень') ||
            lowerFoodName.contains('почки')) {
          return '⚠️ Ограничить при подагре - высокое содержание пуринов';
        }
      }
      
      // Непереносимость лактозы
      if (lowerCondition.contains('лактоз')) {
        if (lowerFoodName.contains('молок') || 
            lowerFoodName.contains('сыр') ||
            lowerFoodName.contains('творог')) {
          return '⚠️ Содержит лактозу';
        }
      }
      
      // Целиакия - глютен
      if (lowerCondition.contains('целиак') || lowerCondition.contains('глютен')) {
        if (lowerFoodName.contains('хлеб') || 
            lowerFoodName.contains('макарон') ||
            lowerFoodName.contains('пшениц')) {
          return '⚠️ Содержит глютен';
        }
      }
    }
    
    return null;
  }
}
