# Сборка IPA для iPhone (аналог `app-release.apk`)

**IPA** — это установочный архив для iOS (то же назначение, что у Android APK/AAB).

## Почему не на Windows

- Сборка под iOS выполняется только **на macOS** с установленным **Xcode** (компилятор, SDK, подпись).
- Текущая установка Flutter **на Windows** в этом проекте не содержит целей `ios` / `ipa` (в `flutter build` доступны только `apk`, `appbundle`, `web`, `windows` и т.д.).

Итог: файл `.ipa` нужно собрать **на Mac** (свой компьютер, Mac коллеги или CI с раннером macOS, например Codemagic / GitHub Actions `macos-latest`).

## Что нужно на Mac

| Требование | Зачем |
|------------|--------|
| macOS, **Xcode** (из App Store) | Компиляция и архив приложения |
| **CocoaPods** (`sudo gem install cocoapods`) | Зависимости нативного iOS-проекта |
| Flutter **полной** установки для macOS | В `flutter doctor` должны быть Xcode и возможность `flutter build ipa` |
| Apple ID / **Apple Developer Program** | Подпись, установка на устройство, TestFlight, App Store |

Дополнительно для Firebase на iOS: в проекте должен быть `GoogleService-Info.plist` в `ios/Runner/` (как `google-services.json` на Android).

## Команды (release, как у APK)

Из корня репозитория:

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

Готовый файл:

- `build/ios/ipa/*.ipa`

## Подпись в Xcode (один раз)

1. Откройте `ios/Runner.xcworkspace` (не `.xcodeproj`).
2. Target **Runner** → **Signing & Capabilities**.
3. Включите **Automatically manage signing**, выберите **Team** (ваша команда разработчика).

После этого `flutter build ipa` сможет архивировать и экспортировать IPA (при корректном профиле).

## Скрипт в репозитории

На Mac из корня проекта:

```bash
chmod +x scripts/build_ipa_macos.sh
./scripts/build_ipa_macos.sh
```

Скрипт выполняет `pub get`, `pod install` и `flutter build ipa --release`.

## Экспорт для магазина

Для загрузки в App Store Connect обычно нужен **App Store** provisioning profile и при необходимости файл **Export Options** (`export-options-plist`). Подробности — в [документации Flutter по развёртыванию iOS](https://docs.flutter.dev/deployment/ios).
