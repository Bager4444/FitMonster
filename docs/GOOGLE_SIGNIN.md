# Настройка входа через Google

В приложении реализован вход через Google в разделе **Профиль**.

## Что нужно сделать

### 1. Google Cloud Console

1. Откройте [Google Cloud Console](https://console.cloud.google.com/).
2. Создайте проект или выберите существующий.
3. Включите **Google Sign-In** (API «Google+» или «Google Identity»):
   - APIs & Services → Library → найдите «Google Sign-In» / «Google+ API» и включите.
4. Создайте учётные данные OAuth 2.0:
   - APIs & Services → Credentials → Create Credentials → **OAuth client ID**.
   - Тип приложения: **Android**.
   - Package name: `com.fitmonster.app`.
   - SHA-1: получите отпечаток ключа (см. ниже) и вставьте в форму.

### 2. SHA-1 для Android

**Debug (разработка):**
```bash
cd android && ./gradlew signingReport
```
В выводе найдите **SHA1** для варианта `debug` и скопируйте в консоль Google.

Или через keytool:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release:** используйте SHA-1 от вашего release-ключа и добавьте второй OAuth client (Android) с этим SHA-1.

### 3. iOS (если нужен вход на iPhone)

1. В Google Cloud Console создайте OAuth client типа **iOS**.
2. Укажите Bundle ID приложения (например, `com.fitmonster.app`).
3. В Xcode / в `ios/Runner/Info.plist` добавьте URL scheme с reversed client ID, как указано в [документации google_sign_in](https://pub.dev/packages/google_sign_in).

### 4. Проверка

После настройки OAuth client:

1. Соберите и запустите приложение.
2. Откройте вкладку **Профиль**.
3. Нажмите **«Войти через Google»** и выберите аккаунт.

При успешном входе отобразятся имя и email от Google, появится кнопка **«Выйти из аккаунта Google»**.
