# Tech Context — FitMonster

## Стек технологий

### Фреймворк
- **Flutter** SDK ^3.10.1 (Dart)
- Кроссплатформенно: iOS 14+, Android 10+, Web (ограниченно), Windows

### State Management
- `provider: ^6.1.1`

### Firebase
- `firebase_core: ^3.8.1`
- `firebase_auth: ^5.3.3`
- Авторизация: Email/Password + Google Sign-In

### Локальное хранилище
- `hive: ^2.2.3` + `hive_flutter: ^1.1.0`
- `shared_preferences: ^2.2.2`
- `path_provider: ^2.1.2`

### ML / Камера
- `google_mlkit_pose_detection: ^0.14.0` — анализ позы
- `camera: ^0.11.3` — работа с камерой
- `mobile_scanner: ^7.1.4` — сканер штрих-кодов (для продуктов)

### UI
- `fl_chart: ^1.1.1` — графики прогресса
- `table_calendar: ^3.1.2` — календарь тренировок
- `intl: ^0.20.2` — локализация (ru)
- Material Design 3

### Сеть
- `dio: ^5.4.0` — HTTP-клиент (AI API)
- `connectivity_plus: ^7.0.0` — проверка сети

### Медиа
- `video_player: ^2.8.1`
- `image_picker: ^1.0.4`
- `file_picker: ^10.3.10`
- `permission_handler: ^12.0.1`

### AI-ассистент
- OpenRouter API: клиент `package:http` и/или `cloud_functions` → Callable `openrouterChat` (Node 20 в `functions/`, секрет OpenRouter в Secret Manager)
- Документация: `lib/features/ai/`

### Dev-зависимости
- `flutter_lints: ^6.0.0`
- `build_runner: ^2.4.8`
- `hive_generator: ^2.0.1`
- `mockito: ^5.4.4`
- `flutter_launcher_icons: ^0.14.3`

## Окружение
- ОС разработки: Windows
- Пакетный менеджер: **bun** (для JS-инструментов), `flutter pub` для Dart
- Линтинг: `flutter_lints` + `analysis_options.yaml`
- VCS: Git, ветка `Dev2`

## CI/CD
- GitHub Actions: `.github/` (детали требуют уточнения)

## Ограничения
- ML Kit не работает на Web (только Android/iOS)
- Firebase показывает предупреждения на Web
- Windows требует Developer Mode для запуска Flutter-приложения
- Иконка приложения: `assets/app_icon.png`, adaptive background `#1a237e`
