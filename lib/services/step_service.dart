import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import '../models/step_data.dart';

// Статус разрешения. Используется в UI для показа разных экранов
enum PermissionState { granted, denied, permanentlyDenied, unknown }

// StepService + ChangeNotifier умеет уведомлять, а WidgetsBindingObserver умеет слушать сворачивание/разворачивание приложения
class StepService extends ChangeNotifier with WidgetsBindingObserver {
  static const _channel = MethodChannel('step_counter'); // Труба для общения с нативным кодом (на Kotlin / Swift)

  // Список целей автопрогрессии
  static const List<int> systemGoals = [
    500, 1000, 5000, 10000, 15000, 20000, 50000, 100000, 200000
  ];

  late SharedPreferences _prefs; // хранилище ключ-значение
  Timer? _pollTimer; // опрос нативных шагов каждую секунду
  Timer? _saveTimer; // сохранение в Hive каждые 30 секунд

  int _todaySteps = 0; // шаги за сегодня
  int _dailyGoal = 10000; // текущая цель
  String _prevDate = ''; // дата предыдущего опроса (для ловли смены дня)
  PermissionState _permission = PermissionState.unknown;
  bool _isRunning = false; // работает ли сервис
  bool _initialized = false; // прошёл ли init()

  bool _useSystemGoals = true; // режим целей: автопрогрессия или кастом
  int _customGoal = 10000; // значение кастомной цели
  int _currentGoalIndex = 0; // текущий индекс в systemGoals

  int _streakDays = 0; // серия дней подряд
  String _lastActiveDate = ''; // последний день активности

  // Флаг "цель достигнута" висит до смены дня или смены цели
  bool _goalReachedPersistent = false;
  String _goalReachedDate = '';
  bool _vibrationSentForCurrentGoal = false;

  int get todaySteps => _todaySteps;
  int get dailyGoal => _dailyGoal;
  PermissionState get permissionState => _permission;
  bool get hasPermission => _permission == PermissionState.granted;
  bool get isRunning => _isRunning;
  bool get isInitialized => _initialized;

  bool get useSystemGoals => _useSystemGoals;
  int get customGoal => _customGoal;
  int get currentGoalIndex => _currentGoalIndex;
  int get streakDays => _streakDays;

  double get km => _todaySteps * 0.00075; // Расчёт километров: примерно 0.75 м на шаг
  int get calories => (_todaySteps * 0.04).round(); // Калории: ~0.04 ккал на шаг
  int get percent => _dailyGoal > 0 // Процент: сколько % от цели, ограничено 999
      ? (_todaySteps / _dailyGoal * 100).round().clamp(0, 999)
      : 0;

  double get goalProgress => _dailyGoal == 0 ? 0 : (_todaySteps / _dailyGoal).clamp(0.0, 1.0); // Прогресс: от 0.0 до 1.0. Защита от деления на ноль

  // Показывать ли плашку "Цель достигнута!"
  // - При своём режиме: да, когда цель достигнута.
  // - При автопрогрессии: НЕТ, кроме последней цели (200К).
  bool get showGoalReached {
    if (!_goalReachedPersistent) return false;
    if (!_useSystemGoals) return true;
    return _currentGoalIndex >= systemGoals.length - 1;
  }

  StepService();

  void _updateEffectiveGoal() { // Обновление цели
    if (_useSystemGoals) { // Режим автопрогрессии - берём из списка по индексу
      _dailyGoal = systemGoals[_currentGoalIndex.clamp(0, systemGoals.length - 1)]; // clamp - защита от выхода за границы массива
    } else {
      _dailyGoal = _customGoal; // Режим кастомной цели
    }
    _prefs.setInt('daily_goal', _dailyGoal);
    if (_isRunning) {
      _channel.invokeMethod('setDailyGoal', {'goal': _dailyGoal}); // Сообщаем нативной части новую цель - она обновит уведомление
    }
  }

  // Проверка: пересчёт цели от текущих шагов + вибрация
  void _checkGoalProgression() {
    if (_useSystemGoals) {
      // Ищем индекс первой цели, которую шаги ещё не превысили
      int newIndex = 0;
      for (int i = 0; i < systemGoals.length; i++) {
        if (_todaySteps < systemGoals[i]) {
          newIndex = i;
          break;
        }
        // шаги превысили все цели - последняя
        newIndex = systemGoals.length - 1;
      }

      // Если индекс изменился, обновляем цель
      if (newIndex != _currentGoalIndex) {
        // Если индекс вырос, сбрасываем флаг вибрации (новая цель = новая вибрация)
        if (newIndex > _currentGoalIndex) {
          _vibrationSentForCurrentGoal = false;
        }
        _currentGoalIndex = newIndex;
        _prefs.setInt('current_goal_index', newIndex);
        _updateEffectiveGoal();
      }
    }

    // Вибрация при достижении текущей цели
    if (_todaySteps >= _dailyGoal && _dailyGoal > 0) {
      if (!_vibrationSentForCurrentGoal) {
        HapticFeedback.heavyImpact();
        _vibrationSentForCurrentGoal = true;
      }
    }

    // Флаг плашки для кастомной цели или для последней цели автопрогрессии
    if (_todaySteps >= _dailyGoal && _dailyGoal > 0) {
      _goalReachedPersistent = true;
      _goalReachedDate = _todayKey;
      _prefs.setBool('goal_reached_persistent', true);
      _prefs.setString('goal_reached_date', _goalReachedDate);
    }
  }

  // Обновляет серию. Растёт только если сегодня есть шаги (> 0).
  void _updateStreak() {
    // Не считаем сегодня активным днём, если шагов 0
    if (_todaySteps <= 0) return;

    final today = _todayKey;
    if (_lastActiveDate == today) return; // Уже обновляли сегодня - ничего не делаем

    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1))); // Вчерашняя дата
    if (_lastActiveDate == yesterday) {
      _streakDays++; // вчера ходил, сегодня ходил - серия растёт
    } else {
      _streakDays = 1; // либо первый день, либо пропуск - начинаем с 1
    }
    _lastActiveDate = today;
    _prefs.setInt('streak_days', _streakDays);
    _prefs.setString('last_active_date', today);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance(); // Открываем SharedPreferences

    // Читаем сохранённые значения, либо дефолты
    _useSystemGoals = _prefs.getBool('use_system_goals') ?? true;
    _customGoal = _prefs.getInt('custom_goal') ?? 10000;
    _currentGoalIndex = _prefs.getInt('current_goal_index') ?? 0;
    _streakDays = _prefs.getInt('streak_days') ?? 0;
    _lastActiveDate = _prefs.getString('last_active_date') ?? '';

    // Восстанавливаем флаг, но только если он с сегодняшего дня
    _goalReachedPersistent =
        _prefs.getBool('goal_reached_persistent') ?? false;
    _goalReachedDate = _prefs.getString('goal_reached_date') ?? '';
    if (_goalReachedDate != _todayKey) { // Флаг со вчера - сбрасываем
      _goalReachedPersistent = false;
      _prefs.setBool('goal_reached_persistent', false);
    }

    _updateEffectiveGoal(); // Устанавливаем эффективную (итоговую) цель

    WidgetsBinding.instance.addObserver(this); // Подписываемся на события жизненного цикла приложения

    try { // Спрашиваем нативную часть: работает ли сервис?
      _isRunning = await _channel.invokeMethod<bool>('isRunning') ?? false;
    } catch (e) {
      debugPrint('StepService: isRunning check failed — $e');
    }
    
    await checkPermissionStatus(); // Проверяем статус разрешений

    // Принудительная проверка смены дня при старте
    final savedToday = StorageService.getStepsForDate(DateTime.now());

    // Сохранённая дата последнего запуска из prefs
    final lastLaunchDate = _prefs.getString('last_launch_date') ?? '';
    final isNewDay = lastLaunchDate.isNotEmpty && lastLaunchDate != _todayKey;

    if (savedToday == null || isNewDay) {
      // Новый день или первый запуск - сбрасываем только шаги
      _todaySteps = 0;

      // Флаг достижения сбрасываем
      _goalReachedPersistent = false;
      _goalReachedDate = '';
      _vibrationSentForCurrentGoal = false;
      _prefs.setBool('goal_reached_persistent', false);
      _prefs.remove('goal_reached_date');
    } else {
      _todaySteps = savedToday.steps;
    }

    // Запоминаем сегодняшнюю дату запуска
    _prefs.setString('last_launch_date', _todayKey);

    if (!_isRunning) {
      try {
        final nativeSteps = await _channel.invokeMethod<int>('getSteps') ?? 0;
        if (nativeSteps > _todaySteps) {
          _todaySteps = nativeSteps;
        }
      } catch (e) {
        debugPrint('StepService: native getSteps fallback — $e');
      }
    } else {
      await _pollSteps();
      _startPolling();
      _startSaveTimer();
    }

    if (!_isRunning) { // Если сервис не работает - пробуем взять шаги из нативного счётчика
      try {
        final nativeSteps = await _channel.invokeMethod<int>('getSteps') ?? 0;
        // Берём максимум, но только если нативная сторона уже видела смену дня
        // (после фикса MainActivity getSteps вернёт 0 при смене дня)
        if (nativeSteps > _todaySteps) {
          _todaySteps = nativeSteps;
        }
      } catch (e) {
        debugPrint('StepService: native getSteps fallback — $e');
      }
    } else { // Сервис работает - запускаем polling (циклический опрос) и таймер сохранения
      await _pollSteps();
      _startPolling();
      _startSaveTimer();
    }

    // Проверяем прогрессию и серию
    _checkGoalProgression();
    _updateStreak();

    // Запоминаем сегодняшнюю дату и помечаем сервис как готовый
    _prevDate = _todayKey;
    _initialized = true;
    notifyListeners();
  }
  
  // Разрешения
  Future<PermissionState> requestPermissions() async {
    PermissionStatus status;

    if (Platform.isAndroid) { // На Android: доступ к активности + показ уведомлений
      status = await Permission.activityRecognition.request();
      await Permission.notification.request();
    } else if (Platform.isIOS) { // На iOS: доступ к сенсорам движения
      status = await Permission.sensors.request();
    } else { // Другие платформы (не наш случай)
      status = PermissionStatus.granted;
    }

    _permission = _mapStatus(status);
    notifyListeners();
    return _permission;
  }

  Future<PermissionState> checkPermissionStatus() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = await Permission.activityRecognition.status;
    } else if (Platform.isIOS) {
      status = await Permission.sensors.status;
    } else {
      status = PermissionStatus.granted;
    }

    _permission = _mapStatus(status);
    notifyListeners();
    return _permission;
  }

  // Открывает системные настройки приложения для случая permanentlyDenied
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  // Возвращает true, если сервис запустился. false - если нет разрешения
  // или нативная сторона не ответила (UI по этому результату покажет подсказку)
  Future<bool> start() async {
    if (!hasPermission) {
      await requestPermissions();
      if (!hasPermission) return false;
    }

    if (Platform.isAndroid) { // На Android просим отключить оптимизацию батареи, иначе система может усыпить сервис
      final batteryStatus =
          await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    try { 
      await _channel.invokeMethod('startService'); // Командуем нативной части запустить сервис
      await _channel.invokeMethod('setDailyGoal', {'goal': _dailyGoal}); // Устанавливаем цель, она придёт в уведомление
      _isRunning = true;
      // Опрашиваем сразу и запускаем таймеры
      await _pollSteps();
      _startPolling();
      _startSaveTimer();
      _updateStreak();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('StepService: start failed — $e');
      return false;
    }
  }

  Future<void> stop() async {
    _pollTimer?.cancel();
    _saveTimer?.cancel();
    saveDailySteps();
    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {
      debugPrint('StepService: stop failed — $e');
    }
    _isRunning = false;
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async { // Каждую 1 секунду спрашиваем у нативной части текущие шаги
      await _pollSteps();
    });
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) { // Каждые 30 секунд сохраняем в Hive, чтобы не терять данные
      saveDailySteps();
    });
  }

  Future<void> _pollSteps() async {
    try {
      final steps = await _channel.invokeMethod<int>('getSteps') ?? 0; // Спрашиваем у нативной части шаги и цель
      final goal = await _channel.invokeMethod<int>('getDailyGoal') ?? _dailyGoal;

      final today = _todayKey;
      if (_prevDate != today && _prevDate.isNotEmpty) {
        // Смена дня - сбрасываем только флаги достижения и шаги
        _goalReachedPersistent = false;
        _goalReachedDate = '';
        _vibrationSentForCurrentGoal = false;
        _prefs.setBool('goal_reached_persistent', false);
        _prefs.remove('goal_reached_date');

        _saveStepsForDateString(_prevDate, _todaySteps);
        _prevDate = today;
      }
      
      // // Если что-то изменилось - обновляем и уведомляем UI
      if (steps != _todaySteps || goal != _dailyGoal) {
        _todaySteps = steps;
        _dailyGoal = goal;
        _prefs.setInt('daily_goal', goal);
        _checkGoalProgression();
        _updateStreak();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('StepService: poll error — $e');
    }
  }

  void saveDailySteps() {
    if (_prevDate.isNotEmpty) {
      _saveStepsForDateString(_prevDate, _todaySteps);
    }
  }

  void _saveStepsForDateString(String dateStr, int steps) {
    // "2026-10-10" -> DateTime(2026, 10, 10)
    final parts = dateStr.split('-');
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    // Сохраняем в Hive
    StorageService.saveStepsForDate(
      StepData(date: dt, steps: steps, goal: _dailyGoal),
    );
  }

  Future<void> resetAllData() async {
    final wasRunning = _isRunning;

    // Если сервис работал - останавливаем его и сохраняем данные
    if (wasRunning) {
      _pollTimer?.cancel();
      _saveTimer?.cancel();
      saveDailySteps();
      try {
        await _channel.invokeMethod('stopService');
      } catch (e) {
        debugPrint('StepService: stop for reset — $e');
      }
      _isRunning = false;
    }

    // Обнуляем всё состояние
    _todaySteps = 0;
    _prevDate = _todayKey;
    _currentGoalIndex = 0;
    _streakDays = 0;
    _lastActiveDate = '';
    _goalReachedPersistent = false;
    _goalReachedDate = '';
    _vibrationSentForCurrentGoal = false;
    _prefs.setInt('current_goal_index', 0);
    _prefs.setInt('streak_days', 0);
    _prefs.remove('last_active_date');
    _prefs.setBool('goal_reached_persistent', false);
    _prefs.remove('goal_reached_date');
    _updateEffectiveGoal();

    // Просим нативную часть сбросить счётчик
    try {
      await _channel.invokeMethod('resetCounter');
    } catch (e) {
      debugPrint('StepService: resetCounter failed — $e');
    }
    
    // Если сервис был запущен, стартуем заново
    if (wasRunning) {
      try {
        await _channel.invokeMethod('startService');
        await _channel.invokeMethod('setDailyGoal', {'goal': _dailyGoal});
        _isRunning = true;
        _startPolling();
        _startSaveTimer();
      } catch (e) {
        debugPrint('StepService: restart after reset — $e');
      }
    }

    notifyListeners();
  }

  void setDailyGoal(int goal) {
    if (goal < 1) goal = 1;
    _customGoal = goal;
    _prefs.setInt('custom_goal', goal);
    if (!_useSystemGoals) { // Если кастомный режим, сразу применяем
      _dailyGoal = goal;
      _prefs.setInt('daily_goal', goal);
      if (_isRunning) {
        _channel.invokeMethod('setDailyGoal', {'goal': goal});
      }
    }
    // Сброс флага при смене цели, достижение неактуально
    _goalReachedPersistent = false;
    _goalReachedDate = '';
    _vibrationSentForCurrentGoal = false;
    _prefs.setBool('goal_reached_persistent', false);
    _prefs.remove('goal_reached_date');

    notifyListeners();
  }

  // Переход к конкретной цели из списка автопрогрессии (тап по чипсу в настройках)
  void setCurrentGoalIndex(int index) {
    if (!_useSystemGoals) return; // имеет смысл только в режиме автопрогрессии
    _currentGoalIndex = index.clamp(0, systemGoals.length - 1);
    _prefs.setInt('current_goal_index', _currentGoalIndex);
    // Сброс флага достижения, как при любой смене цели
    _goalReachedPersistent = false;
    _goalReachedDate = '';
    _vibrationSentForCurrentGoal = false;
    _prefs.setBool('goal_reached_persistent', false);
    _prefs.remove('goal_reached_date');
    _updateEffectiveGoal(); // применит новую цель и отправит её нативной части
    notifyListeners();
  }

  void setUseSystemGoals(bool value) {
    _useSystemGoals = value;
    _prefs.setBool('use_system_goals', value);
    _updateEffectiveGoal();
    // Сброс persistent-флага при смене режима
    _goalReachedPersistent = false;
    _goalReachedDate = '';
    _vibrationSentForCurrentGoal = false;
    _prefs.setBool('goal_reached_persistent', false);
    _prefs.remove('goal_reached_date');
    notifyListeners();
  }

  int getDailyGoal() => _dailyGoal;

  // Текущая дата в виде "yyyy-mm-dd"
  String get _todayKey => _dateKey(DateTime.now());
  
  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
  
  // История за N дней - список (ключ, шаги) от старого к новому
  List<MapEntry<String, int>> getHistory(int days) {
    final result = <MapEntry<String, int>>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final dt = now.subtract(Duration(days: i));
      final key = _dateKey(dt);
      final steps = i == 0 // Для сегодняшнего дня актуальное значение из памяти, для остальных из Hive
          ? _todaySteps
          : (StorageService.getStepsForDate(dt)?.steps ?? 0);
      result.add(MapEntry(key, steps));
    }
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Приложение вернулось из фона -> возобновляем polling
    if (state == AppLifecycleState.resumed && _isRunning) {
      _startPolling();
    } else if (state == AppLifecycleState.paused) { // Приложение ушло в фон -> останавливаем polling и сохраняем
      _pollTimer?.cancel();
      saveDailySteps();
    }
  }

  // Маппинг статусов permission_handler в наш enum
  PermissionState _mapStatus(PermissionStatus s) {
    if (s.isGranted) return PermissionState.granted;
    if (s.isPermanentlyDenied) return PermissionState.permanentlyDenied;
    return PermissionState.denied;
  }

  // При уничтожении снимаем observer, останавливаем таймеры, сохраняем
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _saveTimer?.cancel();
    saveDailySteps();
    super.dispose();
  }
}