# 🚀 Руководство по развертыванию FitMonster

## 📋 Содержание

1. [Подготовка к развертыванию](#подготовка-к-развертыванию)
2. [Android развертывание](#android-развертывание)
3. [iOS развертывание](#ios-развертывание)
4. [Web развертывание](#web-развертывание)
5. [CI/CD настройка](#cicd-настройка)
6. [Мониторинг и аналитика](#мониторинг-и-аналитика)
7. [Обновления приложения](#обновления-приложения)

## 🛠️ Подготовка к развертыванию

### Системные требования:
- **Flutter SDK**: 3.0.0 или выше
- **Dart SDK**: 3.0.0 или выше
- **Android Studio**: 2022.1 или выше (для Android)
- **Xcode**: 14.0 или выше (для iOS)
- **Node.js**: 16.0 или выше (для Web)

### Предварительная настройка:

#### 1. Проверка окружения
```bash
flutter doctor -v
```

#### 2. Обновление зависимостей
```bash
flutter pub get
flutter pub upgrade
```

#### 3. Генерация кода
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 4. Запуск тестов
```bash
flutter test
flutter test integration_test/
```

### Конфигурация для продакшена:

#### `lib/core/constants/app_constants.dart`:
```dart
class AppConstants {
  static const String appName = 'FitMonster';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  
  // Продакшен настройки
  static const bool isProduction = true;
  static const bool enableLogging = false;
  static const int targetFPS = 8;
}
```

#### `pubspec.yaml`:
```yaml
name: fitmonster
description: AI-powered fitness app with exercise recognition
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"
```

## 🤖 Android развертывание

### 1. Настройка подписи приложения

#### Создание keystore:
```bash
keytool -genkey -v -keystore ~/fitmonster-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fitmonster
```

#### `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=fitmonster
storeFile=/path/to/fitmonster-key.jks
```

#### `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.fitmonster.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // ML Kit требует minSdkVersion 21+
        multiDexEnabled true
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### `android/app/proguard-rules.pro`:
```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Hive
-keep class hive.** { *; }
-keep class **$HiveFieldAdapter { *; }
```

### 2. Настройка разрешений

#### `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.fitmonster.app">

    <!-- Разрешения для камеры -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="true" />
    <uses-feature android:name="android.hardware.camera.autofocus" />
    
    <!-- Разрешения для интернета -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Разрешения для хранения -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

    <application
        android:label="FitMonster"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/LaunchTheme"
        android:exported="true"
        android:usesCleartextTraffic="false">
        
        <!-- ML Kit metadata -->
        <meta-data
            android:name="com.google.mlkit.vision.DEPENDENCIES"
            android:value="pose_detection" />
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 3. Сборка для продакшена

#### APK сборка:
```bash
flutter build apk --release --split-per-abi
```

#### App Bundle сборка (рекомендуется для Google Play):
```bash
flutter build appbundle --release
```

#### Проверка размера APK:
```bash
flutter build apk --analyze-size
```

### 4. Тестирование релизной сборки

#### Установка на устройство:
```bash
flutter install --release
```

#### Проверка производительности:
```bash
flutter run --release --profile
```

## 🍎 iOS развертывание

### 1. Настройка Xcode проекта

#### `ios/Runner/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>FitMonster</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>fitmonster</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- Разрешения для камеры -->
    <key>NSCameraUsageDescription</key>
    <string>FitMonster использует камеру для анализа упражнений с помощью искусственного интеллекта</string>
    
    <!-- Минимальная версия iOS -->
    <key>MinimumOSVersion</key>
    <string>11.0</string>
</dict>
</plist>
```

### 2. Настройка подписи и сертификатов

#### В Xcode:
1. Откройте `ios/Runner.xcworkspace`
2. Выберите проект Runner
3. В разделе "Signing & Capabilities":
   - Установите Team
   - Установите Bundle Identifier: `com.fitmonster.app`
   - Включите "Automatically manage signing"

#### Capabilities:
- Camera (для ML Kit)
- Network (для обновлений)

### 3. Сборка для продакшена

#### Сборка IPA:
```bash
flutter build ios --release
```

#### Архивирование в Xcode:
1. Откройте `ios/Runner.xcworkspace`
2. Product → Archive
3. Distribute App → App Store Connect

### 4. App Store Connect настройка

#### Метаданные приложения:
- **Название**: FitMonster
- **Подзаголовок**: AI Fitness Coach
- **Описание**: Умный фитнес-тренер с анализом упражнений
- **Ключевые слова**: fitness, AI, workout, exercise, health
- **Категория**: Health & Fitness
- **Возрастной рейтинг**: 4+

#### Скриншоты:
- iPhone 6.7" (обязательно)
- iPhone 6.5" (обязательно)
- iPhone 5.5"
- iPad Pro 12.9" (для iPad)

## 🌐 Web развертывание

### 1. Настройка для Web

#### `web/index.html`:
```html
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="FitMonster - AI-powered fitness app">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="FitMonster">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>FitMonster</title>
  <link rel="manifest" href="manifest.json">
  
  <style>
    body {
      margin: 0;
      background-color: #1a1a1a;
    }
    .loading {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      color: white;
    }
  </style>
</head>
<body>
  <div class="loading">
    <p>Загрузка FitMonster...</p>
  </div>
  
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    });
  </script>
</body>
</html>
```

#### `web/manifest.json`:
```json
{
    "name": "FitMonster",
    "short_name": "FitMonster",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#1a1a1a",
    "theme_color": "#4CAF50",
    "description": "AI-powered fitness app with exercise recognition",
    "orientation": "portrait-primary",
    "prefer_related_applications": false,
    "icons": [
        {
            "src": "icons/Icon-192.png",
            "sizes": "192x192",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-512.png",
            "sizes": "512x512",
            "type": "image/png"
        },
        {
            "src": "icons/Icon-maskable-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "maskable"
        },
        {
            "src": "icons/Icon-maskable-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "maskable"
        }
    ]
}
```

### 2. Сборка для Web

#### Продакшен сборка:
```bash
flutter build web --release --web-renderer canvaskit
```

#### Оптимизация:
```bash
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### 3. Развертывание на хостинге

#### Firebase Hosting:
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

#### `firebase.json`:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

## 🔄 CI/CD настройка

### GitHub Actions

#### `.github/workflows/build.yml`:
```yaml
name: Build and Deploy

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    - run: flutter pub get
    - run: flutter test
    - run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    - run: flutter pub get
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v3
      with:
        name: android-apk
        path: build/app/outputs/flutter-apk/

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    - run: flutter pub get
    - run: flutter build ios --release --no-codesign
    - uses: actions/upload-artifact@v3
      with:
        name: ios-build
        path: build/ios/iphoneos/

  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    - run: flutter pub get
    - run: flutter build web --release
    - uses: actions/upload-artifact@v3
      with:
        name: web-build
        path: build/web/
```

### Fastlane (для автоматизации iOS/Android)

#### `fastlane/Fastfile`:
```ruby
default_platform(:android)

platform :android do
  desc "Build and upload to Play Store"
  lane :deploy do
    gradle(task: "clean assembleRelease")
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab'
    )
  end
end

platform :ios do
  desc "Build and upload to App Store"
  lane :deploy do
    build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
    upload_to_app_store(
      skip_metadata: true,
      skip_screenshots: true
    )
  end
end
```

## 📊 Мониторинг и аналитика

### Firebase Analytics

#### Настройка:
```dart
// main.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = 
      FirebaseAnalyticsObserver(analytics: analytics);
}
```

#### Отслеживание событий:
```dart
// Начало тренировки
await FirebaseAnalytics.instance.logEvent(
  name: 'workout_started',
  parameters: {
    'exercise_type': 'squats',
    'target_reps': 10,
  },
);

// Завершение тренировки
await FirebaseAnalytics.instance.logEvent(
  name: 'workout_completed',
  parameters: {
    'exercise_type': 'squats',
    'actual_reps': 12,
    'duration_seconds': 180,
  },
);
```

### Crashlytics

#### Настройка:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}
```

## 🔄 Обновления приложения

### Версионирование

#### Семантическое версионирование:
- **Major** (1.0.0 → 2.0.0): Кардинальные изменения
- **Minor** (1.0.0 → 1.1.0): Новые функции
- **Patch** (1.0.0 → 1.0.1): Исправления ошибок

#### `pubspec.yaml`:
```yaml
version: 1.2.3+45
# 1.2.3 - версия приложения
# 45 - номер сборки
```

### Стратегия релизов

#### Каналы распространения:
1. **Internal** - внутреннее тестирование
2. **Alpha** - закрытое тестирование
3. **Beta** - открытое тестирование
4. **Production** - публичный релиз

#### Поэтапное развертывание:
- 1% пользователей → 5% → 20% → 50% → 100%

### Откат изменений

#### Android (Google Play):
- Использование предыдущей версии App Bundle
- Остановка развертывания через консоль

#### iOS (App Store):
- Отзыв версии через App Store Connect
- Ускоренная проверка критических исправлений

## 🔒 Безопасность

### Обфускация кода

#### Android:
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
    }
}
```

#### iOS:
- Автоматическая обфускация при релизной сборке

### Защита API ключей

#### Использование переменных окружения:
```dart
class ApiKeys {
  static const String mlKitKey = String.fromEnvironment('ML_KIT_KEY');
  static const String analyticsKey = String.fromEnvironment('ANALYTICS_KEY');
}
```

#### Сборка с переменными:
```bash
flutter build apk --release --dart-define=ML_KIT_KEY=your_key_here
```

## 📋 Чеклист развертывания

### Перед релизом:
- [ ] Все тесты проходят
- [ ] Код проанализирован (flutter analyze)
- [ ] Версия обновлена в pubspec.yaml
- [ ] Changelog обновлен
- [ ] Иконки и ресурсы оптимизированы
- [ ] Разрешения настроены
- [ ] Подпись приложения настроена
- [ ] Метаданные магазинов обновлены

### После релиза:
- [ ] Мониторинг ошибок активен
- [ ] Аналитика настроена
- [ ] Отзывы пользователей отслеживаются
- [ ] Производительность мониторится
- [ ] План отката готов

---

*Следуя этому руководству, вы сможете успешно развернуть FitMonster на всех поддерживаемых платформах.*