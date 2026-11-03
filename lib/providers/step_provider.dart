import 'package:flutter/foundation.dart';
import '../services/step_service.dart';
import '../services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Обёртка над StepService для UI
// ChangeNotifier умеет уведомлять подписчиков (notifyListeners)
// Когда StepService меняется, StepProvider пересылает notifyListeners и все виджеты, которые делают context.watch<StepProvider>(), перерисовываются
class StepProvider extends ChangeNotifier {
  final StepService _stepService;
  bool _isLoading = false;
  String? _error;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  static const _themeKey = 'theme_mode';

  StepProvider(this._stepService) { // Конструктор. Сразу подписываемся на изменения StepService
    _stepService.addListener(_onServiceChanged);
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey); // 'system' | 'light' | 'dark'
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners(); // сообщаем UI, что тема загружена
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeKey, value);
  }

  void _onServiceChanged() { // Срабатывает, когда StepService уведомляет об изменениях
    notifyListeners();
  }

  int get steps => _stepService.todaySteps;
  int get dailyGoal => _stepService.dailyGoal;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermission => _stepService.hasPermission;
  bool get isRunning => _stepService.isRunning;
  PermissionState get permissionState => _stepService.permissionState;
  double get goalProgress => _stepService.goalProgress;
  double get km => _stepService.km;
  int get calories => _stepService.calories;
  int get percent => _stepService.percent;
  int get streakDays => _stepService.streakDays;
  bool get useSystemGoals => _stepService.useSystemGoals;
  int get customGoal => _stepService.customGoal;
  int get currentGoalIndex => _stepService.currentGoalIndex;
  bool get showGoalReached => _stepService.showGoalReached;

  // Вызывается из main.dart один раз при старте
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _stepService.init();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Возвращает true, если шагомер реально запустился (false - нет разрешения
  // или нативная часть не ответила). UI по этому результату показывает подсказку.
  Future<bool> start() async {
    return _stepService.start();
  }

  Future<void> stop() async {
    await _stepService.stop();
  }

  void updateGoal(int goal) {
    _stepService.setDailyGoal(goal);
  }

  void setUseSystemGoals(bool value) {
    _stepService.setUseSystemGoals(value);
  }

  // Переход к конкретной цели автопрогрессии (тап по чипсу в настройках)
  void setGoalIndex(int index) {
    _stepService.setCurrentGoalIndex(index);
  }

  // Дашборд: суммарная статистика за всё время.
  // Ключи: total (всего шагов), activeDays (дней с шагами > 0), best (лучший день)
  Map<String, int> get statsSummary {
    final all = StorageService.getAllSteps();
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    int total = 0;
    int activeDays = 0;
    int best = 0;
    bool todayIncluded = false;

    for (final d in all) {
      // Для сегодняшнего дня берём актуальное значение из памяти,
      // а не последнее сохранённое в Hive
      final steps = isToday(d.date) ? _stepService.todaySteps : d.steps;
      if (isToday(d.date)) todayIncluded = true;
      total += steps;
      if (steps > 0) activeDays++;
      if (steps > best) best = steps;
    }
    if (!todayIncluded) {
      total += _stepService.todaySteps;
      if (_stepService.todaySteps > 0) activeDays++;
      if (_stepService.todaySteps > best) best = _stepService.todaySteps;
    }

    return {'total': total, 'activeDays': activeDays, 'best': best};
  }

  // Среднее шагов в день за всё время (по дням с активностью)
  int get averageSteps {
    final s = statsSummary;
    final days = s['activeDays'] ?? 0;
    return days > 0 ? ((s['total'] ?? 0) / days).round() : 0;
  }

  // Всего километров за всё время (та же константа 0.75 м/шаг)
  double get totalKmAllTime => (statsSummary['total'] ?? 0) * 0.00075;

  Future<void> resetHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.clearHistory();
      await _stepService.resetAllData();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    await _stepService.requestPermissions();
  }

  Future<void> openSystemSettings() async {
    await _stepService.openSystemSettings();
  }

  List<MapEntry<String, int>> getHistory(int days) {
    return _stepService.getHistory(days);
  }
  
  @override
  void dispose() {
    _stepService.removeListener(_onServiceChanged);
    super.dispose();
  }
}