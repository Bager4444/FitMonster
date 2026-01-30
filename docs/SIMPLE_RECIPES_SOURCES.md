# 🍽️ Простые источники рецептов (без заморочек)

## ⭐ Самые простые варианты (рекомендуется)

### 1. **RecipeNLG Dataset** (GitHub - готовый JSON)

**Самый простой вариант!** Готовый JSON файл на GitHub, можно скачать одной командой.

**Ссылка:** https://github.com/Glorf/RecipeNLG

**Как скачать:**
```powershell
# Создать папку
New-Item -ItemType Directory -Force -Path "assets\data\recipes"

# Скачать напрямую (если есть прямая ссылка на JSON)
# Или клонировать репозиторий
git clone https://github.com/Glorf/RecipeNLG.git temp_recipes
Copy-Item "temp_recipes\*.json" "assets\data\recipes\"
Remove-Item -Recurse -Force "temp_recipes"
```

**Формат:** JSON с полями: `title`, `ingredients`, `directions`, `NER` (named entities)

**Размер:** ~200MB, ~2.3 миллиона рецептов

---

### 2. **Recipe1M+ Dataset** (самый популярный)

**Ссылка:** http://pic2recipe.csail.mit.edu/

**Прямая ссылка на датасет:**
- Основной сайт: http://pic2recipe.csail.mit.edu/dataset/download/
- Или через GitHub: https://github.com/torralba-lab/im2recipe

**Как скачать:**
```powershell
# Скачать через браузер или wget
# Файл: recipe1M_layers.tar.gz
# Распаковать и конвертировать в нужный формат
```

**Формат:** JSON с изображениями и рецептами

**Размер:** ~2GB, ~1 миллион рецептов

---

### 3. **Epicurious Recipes** (Kaggle - но можно скачать без регистрации)

**Ссылка:** https://www.kaggle.com/datasets/hugodarwood/epirecipes

**Альтернатива (GitHub mirror):**
- https://github.com/wkiri/epicurious-recipes
- Или поискать на GitHub: "epicurious recipes json"

**Как скачать:**
```powershell
# Если есть GitHub mirror - просто клонировать
git clone https://github.com/wkiri/epicurious-recipes.git temp
Copy-Item "temp\*.json" "assets\data\recipes\"
```

**Формат:** JSON с полями: `title`, `ingredients`, `directions`, `calories`, `protein`, `fat`, `sodium`

**Размер:** ~20MB, ~20,000 рецептов

---

### 4. **Food.com Recipes** (Kaggle - самый большой)

**Ссылка:** https://www.kaggle.com/datasets/shuyangli94/food-com-recipes-and-user-interactions

**Размер:** ~230,000 рецептов

**Формат:** CSV с полями: `id`, `name`, `minutes`, `contributor_id`, `submitted`, `tags`, `nutrition`, `n_steps`, `steps`, `description`, `ingredients`, `n_ingredients`

**Как скачать:**
1. Зарегистрироваться на Kaggle (бесплатно, 2 минуты)
2. Перейти на страницу датасета
3. Нажать "Download" (или использовать Kaggle API)

**Kaggle API (автоматизация):**
```bash
# Установить Kaggle CLI
pip install kaggle

# Настроить API ключ (скачать с https://www.kaggle.com/account)
# Поместить kaggle.json в ~/.kaggle/

# Скачать датасет
kaggle datasets download -d shuyangli94/food-com-recipes-and-user-interactions -p assets/data/recipes/
```

---

## 🚀 Самый простой вариант (рекомендую начать с этого)

### **RecipeNLG на GitHub** - готовый JSON, скачивается одной командой

```powershell
# Вариант 1: Через PowerShell (если есть прямая ссылка)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Glorf/RecipeNLG/master/recipe_nlg.json" -OutFile "assets\data\recipes\recipes.json"

# Вариант 2: Клонировать репозиторий
git clone https://github.com/Glorf/RecipeNLG.git temp_recipes
# Найти JSON файлы и скопировать
```

---

## 📦 Готовые JSON файлы на GitHub (поиск)

**Просто поищите на GitHub:**
1. Перейдите на https://github.com/search
2. Введите: `recipe dataset json`
3. Выберите репозиторий с готовыми JSON файлами
4. Скачайте файл напрямую (кнопка "Raw")

**Популярные репозитории:**
- https://github.com/topics/recipe-dataset
- https://github.com/topics/recipes-json
- https://github.com/topics/food-recipes

---

## 🔧 Конвертация форматов

Если скачали CSV или другой формат, можно конвертировать в JSON:

### CSV → JSON (Python скрипт)

Создайте файл `convert_recipes.py`:

```python
import csv
import json

# Читаем CSV
recipes = []
with open('recipes.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        recipe = {
            'id': row.get('id', ''),
            'name': row.get('name', ''),
            'nameRu': row.get('name', ''),  # TODO: перевести
            'ingredients': row.get('ingredients', '').split(',') if row.get('ingredients') else [],
            'instructions': row.get('instructions', '').split('.') if row.get('instructions') else [],
            'prepTimeMinutes': int(row.get('prep_time', 0)),
            'cookTimeMinutes': int(row.get('cook_time', 0)),
            'servings': int(row.get('servings', 1)),
            'tags': row.get('tags', '').split(',') if row.get('tags') else [],
        }
        recipes.append(recipe)

# Сохраняем JSON
with open('recipes.json', 'w', encoding='utf-8') as f:
    json.dump(recipes, f, ensure_ascii=False, indent=2)

print(f'Конвертировано {len(recipes)} рецептов')
```

Запуск:
```powershell
python convert_recipes.py
```

---

## 📝 Формат для вашего приложения

Ваш `FoodDataImportService` ожидает такой формат JSON:

```json
[
  {
    "id": "recipe_001",
    "name": "Chicken Curry",
    "nameRu": "Куриное карри",
    "description": "Delicious chicken curry recipe",
    "ingredients": [
      {
        "foodId": "usda_12345",
        "foodName": "Chicken breast",
        "amount": 500,
        "unit": "g",
        "unitRu": "г",
        "calories": 500,
        "protein": 100,
        "fat": 10,
        "carbs": 0
      }
    ],
    "instructions": [
      "Cut chicken into pieces",
      "Cook in pan for 10 minutes"
    ],
    "prepTimeMinutes": 15,
    "cookTimeMinutes": 30,
    "servings": 4,
    "totalCalories": 2000,
    "totalProtein": 100,
    "totalFat": 50,
    "totalCarbs": 200,
    "tags": ["dinner", "protein"]
  }
]
```

---

## 🎯 Рекомендация

**Начните с RecipeNLG на GitHub** - это самый простой вариант:
1. Готовый JSON файл
2. Не нужна регистрация
3. Скачивается одной командой
4. Большой объем данных (2.3M рецептов)

**Если нужен меньший объем для тестирования:**
- Используйте Epicurious Recipes (20K рецептов)
- Или создайте свой небольшой JSON файл для тестирования

---

## 🔗 Полезные ссылки

- [RecipeNLG GitHub](https://github.com/Glorf/RecipeNLG)
- [Recipe1M+ Dataset](http://pic2recipe.csail.mit.edu/)
- [Kaggle Recipe Datasets](https://www.kaggle.com/datasets?search=recipe)
- [GitHub Recipe Topics](https://github.com/topics/recipe-dataset)

---

**Дата создания:** 18 января 2026
