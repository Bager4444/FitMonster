# FitMonster — Cloud Functions (прокси OpenRouter)

Ключ OpenRouter хранится в **Secret Manager**, клиенты его не видят.

Для **секретов** Functions v2 в Google Cloud часто нужен тариф **Blaze** (платёжный аккаунт). Если проект на бесплатном Spark — проверь в консоли Firebase или временно отключи прокси: `--dart-define=AI_USE_CLOUD_PROXY=false` и ключ только в приложении (менее безопасно).

## Один раз

1. В корне репозитория: `firebase login` и `firebase use <projectId>` (или создай `.firebaserc`).

2. Установи зависимости:

   ```bash
   cd functions && npm install
   ```

3. Задай секрет (вставь свой ключ OpenRouter при запросе):

   ```bash
   firebase functions:secrets:set OPENROUTER_API_KEY
   ```

4. Деплой:

   ```bash
   firebase deploy --only functions
   ```

Регион функции: **europe-west1** (как в `index.js`). В приложении задай тот же регион через `--dart-define=FIREBASE_FUNCTIONS_REGION=europe-west1` или поменяй оба файла на `us-central1`.

## Включение в приложении

После успешного деплоя включи прокси в сборке/запуске:

```text
--dart-define=AI_USE_CLOUD_PROXY=true
--dart-define=FIREBASE_FUNCTIONS_REGION=europe-west1
```

Пока **`AI_USE_CLOUD_PROXY=false`** (так по умолчанию в коде), приложение **не** вызывает Firebase и работает только с **своим** ключом OpenRouter (файл `openrouter_user_key.dart` или меню ⋮). Общий ключ на сервере используется только при `true` и задеплоенной функции.

Пользователь должен быть **вошёл по почте** (Firebase Auth), иначе callable вернёт `unauthenticated`.
