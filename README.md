# Футбольный шагомер Edem Walk

Кроссплатформенное приложение (iOS + Android) для подсчёта шагов с элементами футбольной тематики. Считает шаги за день, показывает прогресс до цели, ведёт историю и дашборд, сравнивает ваш километраж с футбольными нормативами. Всё работает локально.

## Возможности

- Подсчёт шагов через системный сенсор
- Прогресс-кольцо с дневной целью
- Автопрогрессия цели (500 -> 200К) или своя цель
- Серия дней подряд
- История за 7 дней (график + список)
- Вибрация при достижении цели
- Тёмная, светлая и системная темы
- **Дашборд** на экране истории: всего шагов / км, среднее за день, лучший день
- **Нормативы футболиста**: выбор позиции (вратарь / защитник / полузащитник / нападающий) и сравнение своего километража за день с нормативом игрока этой позиции за матч
- **Футболисты**: список известных игроков (без фотографий — чужие портреты это авторские права), короткая статья о каждом
- **Кнопка «Актуальные коэффициенты»** в конце статьи (внешняя ссылка). Отключается одной строкой: `showBettingLink` в `lib/data/app_config.dart`

## Правки после ревью (что было исправлено)

- Убраны аватарки/портреты футболистов — авторские права
- iOS: канал `step_counter` теперь регистрируется в `didInitializeImplicitFlutterEngine` (при scene-based lifecycle `window?.rootViewController` был nil, поэтому кнопка старт/стоп и счётчик не работали)
- Чипсы целей в настройках теперь нажимаемые (переключают текущую цель)
- Кнопка старт/стоп показывает понятную подсказку, если нет разрешения
- Полностью убрана геолокация: CoreLocation из AppDelegate, ключи NSLocation* и фоновый режим location из Info.plist. Шагомеру нужен только CMPedometer (NSMotionUsageDescription)

## Важно перед публикацией

- Вставьте свою ссылку в `AppConfig.bettingUrl` (`lib/data/app_config.dart`)
- Кнопка коэффициентов — зона риска для модерации Google Play (политика азартных игр) и App Store (гайдлайн 5.3). При отклонении поставьте `showBettingLink = false`
- Нужны: политика конфиденциальности (URL), возрастной рейтинг, форма Data Safety (Android)

## Стек

- Flutter 3.x / Dart
- Provider — управление состоянием
- Hive + SharedPreferences — локальное хранилище
- fl_chart — графики
- url_launcher — внешние ссылки
- permission_handler — разрешения
- Kotlin (Android) / Swift (iOS) — нативный код сенсоров

## Требования

- Flutter SDK 3.0+ 
- Android SDK + Java JDK (обычно ставятся вместе с Android Studio)
- Для iOS: macOS + Xcode
- Реальное устройство для тестов

```bash
flutter pub get
flutter run
```

Первый запуск может занять 1–3 минуты (Gradle собирает нативную часть). Далее хватает 10–30 секунд.

## Структура проекта

lib/
├── main.dart                          # Точка входа: init Hive, StepService, провайдеры
├── models/
│   ├── step_data.dart                 # Модель шагов за день (Hive)
│   └── user_profile.dart              # Профиль пользователя (Hive)
├── services/
│   ├── step_service.dart              # Ядро: MethodChannel, polling, логика цели
│   └── storage_service.dart           # Обёртка Hive + SharedPreferences
├── providers/
│   ├── step_provider.dart             # ChangeNotifier для UI поверх StepService
│   └── normative_provider.dart        # Выбранная футбольная позиция
├── screens/
│   ├── onboarding_screen.dart         # Запрос разрешений
│   ├── home_screen.dart               # Главный экран
│   ├── normatives_screen.dart         # Нормативы футболиста
│   ├── footballers_screen.dart        # Список футболистов
│   ├── footballer_article_screen.dart # Статья о футболисте
│   ├── settings_screen.dart           # Настройки
│   └── history_screen.dart            # Дашборд + история за 7 дней
└── data/
    ├── app_config.dart                # Выключатель и ссылка «Коэффициенты»
    ├── position_norms.dart            # Нормативы по позициям
    └── footballers.dart               # Карточки и статьи о футболистах

android/app/src/main/
├── AndroidManifest.xml                # Разрешения и регистрация сервиса
├── kotlin/com/example/soccer_pedometer_app/
│   ├── MainActivity.kt                # MethodChannel, маршрутизация вызовов из Dart
│   └── StepCounterService.kt          # Foreground-сервис, слушает TYPE_STEP_COUNTER
└── res/drawable/ic_step.xml           # Иконка для уведомления

ios/Runner/
├── AppDelegate.swift                  # MethodChannel, CMPedometer
└── Info.plist                         # Разрешения

## Как работают файлы и их взаимодействие

#### Android

1. MainActivity.kt создаёт MethodChannel('step_counter') - мост между Dart и Kotlin. Обрабатывает вызовы: startService, stopService, getSteps, getDailyGoal, setDailyGoal, isRunning, resetCounter.
2. Dart вызывает startService -> MainActivity запускает foreground-сервис StepCounterService.kt.
3. StepCounterService.kt подписывается на Sensor.TYPE_STEP_COUNTER (системный счётчик шагов с момента загрузки телефона).
4. Считает шаги за сегодня как totalSteps - baselineSteps. При смене дня baselineSteps сбрасывается на текущее значение сенсора.
5. Сохраняет в SharedPreferences (файл step_counter_prefs). Показывает постоянное уведомление "Шагомер активен".

#### iOS

1. AppDelegate.swift создаёт тот же MethodChannel('step_counter').
2. Dart вызывает startService -> AppDelegate запускает CMPedometer.startUpdates(from: startOfDay).
3. Педометр отдаёт шаги с начала суток, baseline не нужен.
4. Фоновый режим через CLLocationManager (см. UIBackgroundModes: location в Info.plist).

#### Dart

1. main.dart при старте: инициализирует Hive, открывает боксы через StorageService.init(), создаёт StepService и вызывает init(). Оборачивает приложение в MultiProvider.
2. StepService — ядро. Хранит состояние (шаги, цель, серия, разрешения), опрашивает нативную часть раз в секунду через Timer.periodic (polling). Сохраняет в Hive каждые 30 секунд.
3. StepProvider — обёртка над StepService. Когда сервис вызывает notifyListeners(), провайдер пересылает уведомление дальше.
4. Экраны подписываются через context.watch<StepProvider>() — перерисовываются автоматически при изменениях.

### Поток данных

Sensor (TYPE_STEP_COUNTER / CMPedometer)
    ↓
StepCounterService.kt / AppDelegate.swift
    ↓ SharedPreferences (Android) / UserDefaults (iOS)
    ↓ MethodChannel.getSteps()
StepService (Dart) <- опрос раз в секунду
    ↓ notifyListeners()
StepProvider
    ↓ context.watch<StepProvider>()
HomeScreen / HistoryScreen / SettingsScreen

## Разрешения

### Android (AndroidManifest.xml)

ACTIVITY_RECOGNITION — Без него шаги не считаются на Android 10+
FOREGROUND_SERVICE — Работа сервиса в фоне
FOREGROUND_SERVICE_HEALTH — Обязательно на Android 14+
POST_NOTIFICATIONS — Показ уведомления на Android 13+
WAKE_LOCK — CPU не засыпает, пока работает сервис
REQUEST_IGNORE_BATTERY_OPTIMIZATIONS — Попросить отключить оптимизацию батареи

### iOS (Info.plist)

NSMotionUsageDescription — Без него CMPedometer не работает
NSLocationAlwaysAndWhenInUseUsageDescription — Фоновый режим
NSLocationWhenInUseUsageDescription — То же
UIBackgroundModes: location — Фоновый сбор шагов

## Сборка 

```bash
# Универсальный APK (работает на всех устройствах)
flutter build apk --release
# Файл: build/app/outputs/flutter-apk/app-release.apk

# Раздельные APK (меньше размер, по архитектурам)
flutter build apk --split-per-abi --release
# Для современных телефонов — app-arm64-v8a-release.apk

# iOS (только macOS)
flutter build ipa

# Пересобрать иконки приложения (после замены assets/icon/app_icon.png)
dart run flutter_launcher_icons
```