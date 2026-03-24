# Progress — FitMonster

## Общий статус
- Прогресс MVP по deliverables: см. `memory_bank/projectbrief.md` → **## Project Deliverables** (взвешенная готовность по статусам и весам).
- Неделя: 9 из 15
- Текущий спринт: Спринт 3 (Упражнения с ML) — 75%

## Что готово

| Модуль | Статус | Прогресс |
|--------|--------|----------|
| Профиль и статистика | ✅ Завершён | 100% |
| Диета и трекер питания | ✅ Завершён | 100% |
| Авторизация (Email + Google) | ✅ Завершён | 100% |
| Камера + ML Kit (поза) | ✅ Завершён | 100% |
| Подсчёт повторений | ✅ Завершён | 100% |
| Анализ техники упражнений | 🔄 В работе | 50% |
| AI-ассистент (DeepSeek API) | ✅ Интегрирован | 100% |
| Интеграция модулей (Спринт 4) | ⏳ Запланирован | 0% |
| Тестирование | ⏳ В процессе | 15% |

## Known Issues (Известные проблемы)

1. ⚠️ ML Kit не работает на Web (только Android/iOS)
2. ⚠️ Firebase показывает предупреждения на Web
3. ⚠️ Windows требует Developer Mode для запуска
4. ⚠️ Тестовое покрытие ~15% (цель: 80%)

## Changelog

### 2026-03-24 — AGENTS.md и Project Deliverables
- Корневой `AGENTS.md` синхронизирован с каноном `projects-tracker` (Memory Bank, deliverables, Biome без `*.md`, режимы планирования).
- В `projectbrief.md` добавлен раздел **## Project Deliverables** (таблица `ID | Deliverable | Status | Weight`, сумма весов 100).

### 2026-03-21 — Документация сборки IPA (iOS)
- `docs/build_ios_ipa.md`: аналог release APK для iPhone; ограничение Windows / отсутствие `flutter build ipa` в Windows-SDK
- `scripts/build_ipa_macos.sh`: `pod install` + `flutter build ipa --release` на macOS

### 2026-03-21 — Рейтинг на экране «Профиль»
- Таблица топ-12 по `UserAccountService.sortedAccountsByRating()` / `ratingScore`, подсветка текущего пользователя, строка «Ваше место … из … · балл …», пояснение что рейтинг локальный (Hive на устройстве)
- Кнопка обновления вызывает `refreshRanks()` и перезагрузку данных

### 2026-03-23 — Firestore: синк UserAccount
- Зависимость `cloud_firestore`; сервис `lib/core/services/user_account_firestore_sync.dart` (push/pull, сравнение `updatedAt`)
- Колбэк `UserAccountService.attachFirestorePush` регистрируется в `main.dart` после успешного `Firebase.initializeApp`
- `UserAccount.copyWith` дополнен параметром `id` для слияния с облаком
- Гости `user_*` в Firestore не пишутся; только `firebase_<uid>`

### 2026-03-21 — План синхронизации Firestore
- Добавлен `docs/specs/firestore_sync_plan.md`: модель коллекций, Security Rules, фазы внедрения, список действий в Firebase Console
- В `docs/README.md` — ссылка на спецификацию; в `activeContext` зафиксирован режим «план утверждается, код после ОК»

### 2026-03-20 — Единая БД пользователей
- Добавлена модель `UserAccount` и сервис `UserAccountService` для хранения данных пользователя в `Hive.users`
- Реализованы поля: имя, email, hash пароля, ударный режим, суммарные упражнения, время выполнения, средний процент, ачивки, 3 последних устройства, аллергии, противопоказания, подписка, мировой и региональный рейтинг
- Подключена синхронизация с `AuthService`, `WorkoutService`, `ProfileService` и сохранением профиля питания
- Добавлена миграция legacy-данных (никнейм/часть статистики/медданные) в новый формат аккаунта
- Приложение пересобрано и обновлено на Android эмуляторе (`Medium_Phone`)

### 2026-03-20 — AI помощник на DeepSeek
- Убрано хранение API-ключа в коде, добавена конфигурация через `--dart-define=DEEPSEEK_API_KEY=...`
- Контекст для DeepSeek расширен данными пользователя из `UserAccount` (подписка, рейтинг, средний процент техники)
- История AI-чата разделена по пользователям (`ai_messages_<userId>`)
- Добавлен корректный офлайн-ответ при отсутствии API-ключа
- `AppProfile` расширен полями аллергий и противопоказаний для персонализации AI-ответов

### 2026-03-20 — Фикс лагов при запуске и обновление на эмуляторе
- Исправлена миграция локальной базы продуктов: повторная очистка/переимпорт на каждом старте отключены
- Снижен шум рендер-ошибок: устранен `RenderFlex overflow` в карточке упражнений
- Приложение пересобрано и обновлено на Android эмуляторе (`Medium_Phone`)

### 2026-03-20 — Инициализация Memory Bank
- Создана структура `/memory_bank/` (Режим В)
- Заполнены: projectbrief.md, productContext.md, activeContext.md, systemPatterns.md, techContext.md, progress.md
- Проведён первичный ресёрч репозитория

### 2026-01-15 — Камера переделана (Camerawork)
- Улучшена обработка кадров (защита от перегрузки)
- Полный набор соединений скелета (как в MediaPipe)
- Точный подсчёт повторений на основе анализа углов
- Производительность ~10-15 FPS

### AI-ассистент (DeepSeek API)
- Интеграция DeepSeek API
- Расширенная база знаний
- Документация: `lib/features/ai/`

## Контроль изменений

```
last_checked_commit: acf3eb6
branch: Dev2
date: 2026-03-24
message: docs: синхронизация AGENTS.md с projects-tracker и таблица Project Deliverables
```
