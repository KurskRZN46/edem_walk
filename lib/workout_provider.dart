import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/step_service.dart';
import '../data/workouts.dart';
import '../data/league.dart' show weekKey;

// Фазы интервальной тренировки: не начата -> идёт -> завершена
enum WorkoutState { idle, running, finished }

// Логика интервальной тренировки: ведёт пользователя по фазам,
// свистит на смене темпа, считает шаги и калории за тренировку.
// Статистика (сколько тренировок пройдено, общее время) хранится
// в SharedPreferences и читается CareerProvider для достижений.
class WorkoutProvider extends ChangeNotifier {
  final StepService _service;

  // Ключи SharedPreferences
  static const kWorkoutsDone = 'workouts_done'; // всего тренировок пройдено
  static const kWorkoutSeconds = 'workout_seconds_total'; // суммарное время
  static const _kPlanDifficulty = 'plan_difficulty'; // 0 лёгкий / 1 стандарт / 2 профи
  static const _kPlanDoneWeek = 'plan_done_week'; // неделя отметок выполнения
  static const _kPlanDoneDays = 'plan_done_days'; // отмеченные дни ("0","3"...)

  Timer? _timer;
  SharedPreferences? _prefs;
  final AudioPlayer _audio = AudioPlayer(); // свисток и финальные свистки

  // Проиграть звук (ошибки глушим - на эмуляторе без звука не должно падать)
  void _play(String file) {
    try {
      _audio.play(AssetSource('audio/$file'));
    } catch (_) {}
  }

  WorkoutProvider(this._service);

  // --- Состояние активной тренировки ---
  WorkoutState state = WorkoutState.idle;
  IntervalWorkout? workout; // выбранная тренировка
  int phaseIndex = 0; // номер текущей фазы
  int elapsedInPhase = 0; // секунд прошло в текущей фазе
  int elapsedTotal = 0; // секунд прошло всего
  int _baseline = 0; // шаги на момент старта

  // --- Накопленная статистика ---
  int workoutsDone = 0; // сколько тренировок завершено за всё время
  int totalSeconds = 0; // суммарное время тренировок

  // --- План недели: сложность и отметки ---
  int planDifficulty = 1; // 0/1/2
  Set<int> doneDays = {}; // отмеченные дни текущей недели (0 = Пн)

  static const _difficultyMultipliers = [0.8, 1.0, 1.3];
  static const difficultyNames = ['Лёгкий', 'Стандарт', 'Профи'];

  // Множитель целей плана по выбранной сложности
  double get difficultyMultiplier => _difficultyMultipliers[planDifficulty];

  // Цель дня с учётом сложности
  int scaledSteps(int baseSteps) => (baseSteps * difficultyMultiplier).round();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    workoutsDone = _prefs!.getInt(kWorkoutsDone) ?? 0;
    totalSeconds = _prefs!.getInt(kWorkoutSeconds) ?? 0;
    planDifficulty = (_prefs!.getInt(_kPlanDifficulty) ?? 1).clamp(0, 2);
    _loadDoneDays();
    notifyListeners();
  }

  // --- Отметки выполнения дней плана ---

  void _loadDoneDays() {
    final savedWeek = _prefs!.getString(_kPlanDoneWeek);
    final currentWeek = weekKey(DateTime.now());
    if (savedWeek != currentWeek) {
      // Новая неделя - отметки обнуляются
      doneDays = {};
      _prefs!.setString(_kPlanDoneWeek, currentWeek);
      _prefs!.setStringList(_kPlanDoneDays, const []);
      return;
    }
    doneDays = (_prefs!.getStringList(_kPlanDoneDays) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  bool isDayDone(int index) => doneDays.contains(index);

  int get weekDoneCount => doneDays.length;

  // Отметить/снять отметку "день выполнен"
  void toggleDayDone(int index) {
    if (doneDays.contains(index)) {
      doneDays.remove(index);
    } else {
      doneDays.add(index);
    }
    _prefs?.setStringList(
      _kPlanDoneDays,
      doneDays.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  // Выбор сложности плана
  void setDifficulty(int level) {
    planDifficulty = level.clamp(0, 2);
    _prefs?.setInt(_kPlanDifficulty, planDifficulty);
    notifyListeners();
  }

  // --- Активная тренировка ---

  // Текущая фаза (null, если тренировка не идёт)
  WorkoutPhase? get currentPhase =>
      workout != null && phaseIndex < workout!.phases.length
          ? workout!.phases[phaseIndex]
          : null;

  // Следующая фаза (для подсказки "далее")
  WorkoutPhase? get nextPhase =>
      workout != null && phaseIndex + 1 < workout!.phases.length
          ? workout!.phases[phaseIndex + 1]
          : null;

  // Прогресс текущей фазы 0.0 - 1.0
  double get phaseProgress {
    final p = currentPhase;
    if (p == null || p.seconds == 0) return 0;
    return (elapsedInPhase / p.seconds).clamp(0.0, 1.0);
  }

  // Прогресс всей тренировки 0.0 - 1.0
  double get totalProgress {
    final w = workout;
    if (w == null || w.totalSeconds == 0) return 0;
    return (elapsedTotal / w.totalSeconds).clamp(0.0, 1.0);
  }

  // Осталось секунд в текущей фазе
  int get phaseRemaining {
    final p = currentPhase;
    if (p == null) return 0;
    return (p.seconds - elapsedInPhase).clamp(0, p.seconds);
  }

  // Осталось секунд до конца тренировки
  int get totalRemaining {
    final w = workout;
    if (w == null) return 0;
    return (w.totalSeconds - elapsedTotal).clamp(0, w.totalSeconds);
  }

  // Шаги, пройденные за тренировку (по дельте от старта)
  int get workoutSteps =>
      (_service.todaySteps - _baseline).clamp(0, 1 << 31);

  // Калории за тренировку (та же формула, что в шагомере)
  int get workoutCalories => (workoutSteps * 0.04).round();

  // Старт тренировки. Возвращает false, если не удалось запустить
  // шагомер (нет разрешения) - UI покажет подсказку
  Future<bool> start(IntervalWorkout w) async {
    // Шагомер должен работать, иначе шаги не засчитаются
    if (!_service.isRunning) {
      final started = await _service.start();
      if (!started) return false;
    }

    _timer?.cancel();
    workout = w;
    phaseIndex = 0;
    elapsedInPhase = 0;
    elapsedTotal = 0;
    _baseline = _service.todaySteps;
    state = WorkoutState.running;
    _play('whistle.wav'); // свисток на старт!
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
    return true;
  }

  void _tick() {
    if (state != WorkoutState.running) return;
    final w = workout;
    if (w == null) return;

    elapsedInPhase++;
    elapsedTotal++;

    if (elapsedInPhase >= w.phases[phaseIndex].seconds) {
      // Фаза закончилась - переходим к следующей
      phaseIndex++;
      elapsedInPhase = 0;
      if (phaseIndex >= w.phases.length) {
        _finish(); // все фазы пройдены
        return;
      }
      _play('whistle.wav'); // свисток на смену темпа
    }
    notifyListeners();
  }

  // Завершить досрочно (прогресс всё равно засчитывается)
  void finishEarly() {
    if (state != WorkoutState.running) return;
    _finish();
  }

  void _finish() {
    _timer?.cancel();
    state = WorkoutState.finished;
    _play('fulltime.wav'); // финальные свистки!

    // Сохраняем статистику (учитываем даже досрочное завершение,
    // если прошло хотя бы 2 минуты)
    if (elapsedTotal >= 120) {
      workoutsDone++;
      totalSeconds += elapsedTotal;
      _prefs?.setInt(kWorkoutsDone, workoutsDone);
      _prefs?.setInt(kWorkoutSeconds, totalSeconds);
    }
    notifyListeners();
  }

  // Вернуться к списку тренировок (с экрана итогов)
  void backToList() {
    _timer?.cancel();
    state = WorkoutState.idle;
    workout = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    super.dispose();
  }
}
