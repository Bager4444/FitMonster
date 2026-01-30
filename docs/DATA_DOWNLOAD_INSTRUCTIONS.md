# Инструкции по скачиванию данных для модуля диеты

## 📋 Обзор

Для работы модуля диеты необходимо скачать данные о продуктах и рецептах из открытых источников.

---

## 🥗 USDA FoodData Central

### Что это?
USDA FoodData Central — официальная база данных о продуктах питания от Министерства сельского хозяйства США. Содержит информацию о питательной ценности более 375,000 продуктов.

### Где скачать?

1. **Официальный сайт:**
   - URL: https://fdc.nal.usda.gov/download-datasets.html
   - Выберите формат: CSV или JSON

2. **Рекомендуемые наборы данных:**

   **Foundation Foods** (рекомендуется для начала):
   - Размер: ~50-100 MB
   - Количество продуктов: ~8,000
   - Формат: CSV или JSON
   - Ссылка: https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_Foundation_Foods_csv_2024-10-15.zip
   
   **Полная база данных:**
   - Размер: ~500 MB - 2 GB
   - Количество продуктов: 375,000+
   - Формат: CSV или JSON
   - Ссылка: https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2024-10-15.zip

### Как скачать?

#### Вариант 1: Через браузер
1. Перейдите на https://fdc.nal.usda.gov/download-datasets.html
2. Выберите нужный набор данных (рекомендуется Foundation Foods)
3. Скачайте ZIP архив
4. Распакуйте архив
5. Скопируйте CSV/JSON файл в папку проекта: `assets/data/usda/`

#### Вариант 2: Через командную строку (Windows PowerShell)
```powershell
# Создать папку для данных
New-Item -ItemType Directory -Force -Path "assets\data\usda"

# Скачать Foundation Foods (пример URL, обновите на актуальный)
Invoke-WebRequest -Uri "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_Foundation_Foods_csv_2024-10-15.zip" -OutFile "assets\data\usda\usda_foundation.zip"

# Распаковать (требуется 7-Zip или WinRAR)
# Или используйте встроенный Expand-Archive
Expand-Archive -Path "assets\data\usda\usda_foundation.zip" -DestinationPath "assets\data\usda\" -Force
```

### Структура данных USDA

**CSV формат:**
- Колонки: `fdc_id`, `description`, `data_type`, `publication_date`, `ndb_number`, `foodNutrients`, ...
- Основные поля:
  - `fdc_id` — уникальный ID продукта
  - `description` — название продукта
  - `foodNutrients` — массив нутриентов (калории, белки, жиры, углеводы)

**JSON формат:**
```json
{
  "fdc_id": 173944,
  "description": "Apple, raw",
  "foodNutrients": [
    {
      "nutrient": {"id": 1008, "name": "Energy"},
      "amount": 52
    },
    {
      "nutrient": {"id": 1003, "name": "Protein"},
      "amount": 0.26
    }
  ]
}
```

### Nutrient IDs (важные):
- `1008` — Energy (калории)
- `1003` — Protein (белок)
- `1004` — Total lipid (жир)
- `1005` — Carbohydrate, by difference (углеводы)

---

## 🍽️ Рецепты

### ⭐ Самый простой вариант (рекомендуется)

#### **RecipeNLG Dataset** (GitHub - готовый JSON)

**Самый простой способ!** Готовый JSON файл, скачивается одной командой.

**Ссылка:** https://github.com/Glorf/RecipeNLG

**Как скачать:**
```powershell
# Создать папку
New-Item -ItemType Directory -Force -Path "assets\data\recipes"

# Вариант 1: Клонировать репозиторий
git clone https://github.com/Glorf/RecipeNLG.git temp_recipes
# Найти JSON файлы и скопировать в assets/data/recipes/

# Вариант 2: Скачать напрямую (если есть прямая ссылка)
# Invoke-WebRequest -Uri "https://raw.githubusercontent.com/..." -OutFile "assets\data\recipes\recipes.json"
```

**Формат:** JSON с полями: `title`, `ingredients`, `directions`

**Размер:** ~200MB, ~2.3 миллиона рецептов

**Подробнее:** См. `docs/SIMPLE_RECIPES_SOURCES.md`

---

### Другие источники

#### 1. Kaggle Datasets
- URL: https://www.kaggle.com/datasets?search=recipe
- Популярные датасеты:
  - "Recipe Ingredients Dataset" — ~200,000 рецептов
  - "Epicurious Recipes" — ~20,000 рецептов
  - "Food.com Recipes and Interactions" — ~230,000 рецептов

**Как скачать:**
1. Зарегистрируйтесь на Kaggle (бесплатно)
2. Найдите нужный датасет
3. Нажмите "Download" (или используйте Kaggle API)
4. Распакуйте архив
5. Скопируйте JSON файл в `assets/data/recipes/`

**Kaggle API (для автоматизации):**
```bash
# Установить Kaggle CLI
pip install kaggle

# Настроить API ключ (скачать с https://www.kaggle.com/account)
# Поместить kaggle.json в ~/.kaggle/

# Скачать датасет
kaggle datasets download -d [dataset-name] -p assets/data/recipes/
```

#### 2. GitHub репозитории (без регистрации)
- Поиск: https://github.com/search?q=recipe+dataset+json
- Примеры:
  - https://github.com/topics/recipe-dataset
  - https://github.com/topics/food-recipes
- Просто скачайте JSON файл напрямую (кнопка "Raw")

#### 2. GitHub репозитории
- Поиск: https://github.com/search?q=recipe+dataset+json
- Примеры:
  - https://github.com/topics/recipe-dataset
  - https://github.com/topics/food-recipes

#### 3. Open Recipes
- URL: https://www.openrecipes.org/
- Открытая база рецептов в JSON формате

### Формат данных рецептов

**Ожидаемый JSON формат:**
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
        "unitRu": "г"
      }
    ],
    "instructions": [
      "Cut chicken into pieces",
      "Cook in pan for 10 minutes"
    ],
    "prepTimeMinutes": 15,
    "cookTimeMinutes": 30,
    "servings": 4,
    "tags": ["dinner", "protein"]
  }
]
```

---

## 📦 Open Food Facts (для штрих-кодов)

### Что это?
Open Food Facts — открытая база данных продуктов со штрих-кодами. Содержит миллионы продуктов с информацией о питательной ценности.

### Где скачать?

1. **Официальный сайт:**
   - URL: https://world.openfoodfacts.org/data
   - Формат: JSON (gzip сжатый)

2. **Рекомендуемые файлы:**
   - `products.json.gz` — полная база (несколько GB)
   - `products_en.json.gz` — только английские продукты (меньший размер)

### Как скачать?

```powershell
# Создать папку
New-Item -ItemType Directory -Force -Path "assets\data\openfoodfacts"

# Скачать (пример URL, обновите на актуальный)
Invoke-WebRequest -Uri "https://static.openfoodfacts.org/data/products.json.gz" -OutFile "assets\data\openfoodfacts\products.json.gz"

# Распаковать (требуется 7-Zip или другой архиватор)
```

### Структура данных Open Food Facts

```json
{
  "code": "3017620422003",
  "product_name": "Nutella",
  "nutriments": {
    "energy-kcal_100g": 539,
    "proteins_100g": 6.3,
    "fat_100g": 30.9,
    "carbohydrates_100g": 57.5
  },
  "allergens": "gluten,milk",
  "categories": "Spreads, Breakfasts"
}
```

---

## 📁 Структура папок проекта

После скачивания данных, создайте следующую структуру:

```
assets/
  data/
    usda/
      foundation_foods.csv (или .json)
      # или полная база:
      food_data_central.csv
    recipes/
      recipes.json
    openfoodfacts/
      products.json.gz (или распакованный .json)
```

**Важно:** Добавьте папку `assets/data/` в `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/data/
```

---

## 🚀 Использование данных

После скачивания данных, используйте `FoodDataImportService` для импорта:

```dart
import 'package:fitmonster/features/diet/data/services/food_data_import_service.dart';

final importService = FoodDataImportService();

// Импорт USDA данных
await importService.importUSDAJson(
  'assets/data/usda/foundation_foods.json',
  onProgress: (current, total) {
    print('Прогресс: $current / $total');
  },
);

// Импорт рецептов
await importService.importRecipes(
  'assets/data/recipes/recipes.json',
);

// Создание индекса поиска
await importService.buildSearchIndex();
```

---

## ⚠️ Важные замечания

1. **Размер файлов:**
   - USDA Foundation Foods: ~50-100 MB
   - USDA Full Database: ~500 MB - 2 GB
   - Open Food Facts: несколько GB
   - Рецепты: зависит от датасета (обычно 10-100 MB)

2. **Первая загрузка:**
   - Импорт может занять несколько минут
   - Рекомендуется показывать прогресс-бар пользователю
   - Можно импортировать в фоновом режиме

3. **Обновление данных:**
   - USDA обновляется ежеквартально
   - Рекомендуется обновлять данные раз в 3-6 месяцев
   - Open Food Facts обновляется ежедневно

4. **Локализация:**
   - USDA данные в основном на английском
   - Потребуется перевод названий продуктов на русский
   - Можно использовать Google Translate API или словари

---

## 🔗 Полезные ссылки

- [USDA FoodData Central](https://fdc.nal.usda.gov)
- [USDA Download Datasets](https://fdc.nal.usda.gov/download-datasets.html)
- [Open Food Facts](https://world.openfoodfacts.org)
- [Open Food Facts Data](https://world.openfoodfacts.org/data)
- [Kaggle Recipe Datasets](https://www.kaggle.com/datasets?search=recipe)
- [Kaggle API Documentation](https://www.kaggle.com/docs/api)

---

**Дата создания:** 18 января 2026  
**Последнее обновление:** 18 января 2026
