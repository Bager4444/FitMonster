# Active Context — FitMonster

## Текущий фокус
- Канон прогресса MVP: таблица **## Project Deliverables** в `memory_bank/projectbrief.md` (обновлять статусы после задач, влияющих на scope).
- **Firestore:** синхронизация `UserAccount` (без `passwordHash`) — `UserAccountFirestoreSync`, путь `users/{uid}/sync/account`; push из `UserAccountService`, pull после входа/restore в `AuthService`. См. `docs/specs/firestore_sync_plan.md`.
- **Рейтинг в профиле:** топ-12 и место пользователя по локальным аккаунтам в Hive; обновление позиций — `refreshRanks()` (и при необходимости push в облако).
- Единая локальная БД пользователей (`Hive.users`), Firebase Auth (почта), AI на OpenRouter (файл `lib/core/config/openrouter_user_key.dart`, опционально SharedPreferences / `OPENROUTER_API_KEY`).
- Текущая ветка: `Dev2`

## Активный спринт
**Спринт 3: Упражнения с ML** (75% готово)
- ✅ Камера (переделана на Camerawork)
- ✅ ML Kit интеграция (google_mlkit_pose_detection)
- ✅ Отрисовка скелета
- ✅ Подсчёт повторений (анализ углов)
- ⏳ Расширенный анализ техники упражнений

## Следующий спринт
**Спринт 4: Интеграция** (запланирован, недели 11-12)

## Активные решения и приоритеты
1. Завершить анализ техники упражнений (Спринт 3)
2. Начать Спринт 4: интеграция всех модулей
3. Улучшить тестовое покрытие (сейчас ~15%, цель 80%)

## Известные неопределённости
- Точный шаблон активной темы (тёмная/светлая) — см. `lib/core/theme/`
- AI-ассистент (OpenRouter): по умолчанию прямой вызов со своим ключом; облако — `AI_USE_CLOUD_PROXY=true` после `firebase deploy` (Callable `openrouterChat`, секрет `OPENROUTER_API_KEY`, регион `europe-west1`). См. `functions/README.md`.
