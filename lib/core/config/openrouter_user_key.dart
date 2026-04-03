/// Собственный API-ключ OpenRouter (если не пользуешься облачным прокси или как запасной).
///
/// Общий ключ на сервере: задеплой `functions/` и секрет `OPENROUTER_API_KEY` — см. `functions/README.md`.
/// Облако: после `firebase deploy` собери с `--dart-define=AI_USE_CLOUD_PROXY=true` — тогда при входе по почте ключ на устройстве не нужен.
///
/// Свой ключ: https://openrouter.ai/keys — вставь между кавычками (sk-or-v1-...).
/// Модель: `--dart-define=OPENROUTER_MODEL=...` — https://openrouter.ai/models
///
/// Не коммить реальный ключ в публичный репозиторий.
const String kOpenRouterUserApiKey = '';
