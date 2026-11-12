import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/step_service.dart';
import '../data/commentary.dart';

// Фазы матча: не начат -> идёт -> завершён
enum MatchPhase { idle, running, finished }

// Одна реплика комментатора в ленте событий
class MatchEventItem {
  final int minute; // "футбольная" минута (1-90 независимо от длительности)
  final String text;
  final bool highlight; // голы и финал подсвечиваем

  const MatchEventItem(this.minute, this.text, {this.highlight = false});
}

// Логика режима «Матч»: таймер, голы за шаги, комментатор, статистика.
// Гол начисляется за каждые [stepsPerGoal] шагов, пройденных после старта матча.
class MatchProvider extends ChangeNotifier {
  final StepService _service;

  static const int stepsPerGoal = 1500; // сколько шагов нужно для одного гола
  static const List<int> availableDurations = [15, 30, 45, 90]; // минуты

  // Ключи SharedPreferences: незавершённый матч переживает перезапуск приложения
  static const _kActive = 'match_active';
  static const _kStartMillis = 'match_start_millis';
  static const _kBaseline = 'match_baseline';
  static const _kDuration = 'match_duration_min';
  static const _kOppGoals = 'match_opp_goals';

  // Карьерная статистика матчей (читает CareerProvider)
  static const kCareerMatches = 'career_matches';
  static const kCareerWins = 'career_wins';
  static const kCareerGoals = 'career_goals';
  static const kCareerBestGoals = 'career_best_goals';
  static const kLastMatchDate = 'career_last_match_date'; // дата последнего матча "yyyy-mm-dd"

  final Random _rnd = Random();
  Timer? _timer;
  SharedPreferences? _prefs;
  final AudioPlayer _audio = AudioPlayer(); // звуки стадиона

  // Проиграть звук из assets/audio (ошибки глушим: звук - приятный бонус,
  // а не критичная функция, на эмуляторе без звука не должно падать)
  void _play(String file) {
    try {
      _audio.play(AssetSource('audio/$file'));
    } catch (_) {}
  }

  MatchPhase phase = MatchPhase.idle;
  int durationMin = 90; // выбранная длительность
  DateTime? _startTime;
  int _baseline = 0; // шаги на момент старта матча
  int _elapsedSec = 0;
  int myGoals = 0;
  int oppGoals = 0;
  String result = ''; // 'win' | 'draw' | 'loss'
  bool _halfTimeShown = false;
  int _lastAmbientSec = 0;
  final List<MatchEventItem> events = [];

  MatchProvider(this._service);

  // --- Геттеры для UI ---

  int get elapsedSeconds => _elapsedSec;
  int get totalSeconds => durationMin * 60;

  // Шаги, пройденные с начала матча
  int get matchSteps =>
      phase == MatchPhase.idle ? 0 : max(0, _service.todaySteps - _baseline);

  // Прогресс матча по времени 0.0 - 1.0
  double get timeProgress => totalSeconds == 0
      ? 0
      : (_elapsedSec / totalSeconds).clamp(0.0, 1.0);

  // "Футбольная" минута 1-90: даже 15-минутный матч идёт как полноценный
  int get footballMinute => totalSeconds == 0
      ? 1
      : ((_elapsedSec / totalSeconds) * 90).ceil().clamp(1, 90);

  // Шаги до следующего гола
  int get stepsToNextGoal => stepsPerGoal - (matchSteps % stepsPerGoal);

  // Прогресс до следующего гола 0.0 - 1.0
  double get nextGoalProgress => (matchSteps % stepsPerGoal) / stepsPerGoal;

  // Форматированное время "ММ:СС"
  String get clock {
    final m = (_elapsedSec ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Восстановление незавершённого матча после перезапуска приложения
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final active = _prefs!.getBool(_kActive) ?? false;
    if (!active) return;

    final startMillis = _prefs!.getInt(_kStartMillis) ?? 0;
    durationMin = _prefs!.getInt(_kDuration) ?? 90;
    _baseline = _prefs!.getInt(_kBaseline) ?? 0;
    oppGoals = _prefs!.getInt(_kOppGoals) ?? 0;
    _startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);

    _elapsedSec = DateTime.now().difference(_startTime!).inSeconds;
    if (_elapsedSec >= totalSeconds) {
      // Матч должен был закончиться, пока приложение было закрыто:
      // сразу фиксируем результат, ленту событий начинаем с финального свистка
      myGoals = matchSteps ~/ stepsPerGoal;
      events.clear();
      _finish();
      return;
    }

    // Матч ещё идёт - возобновляем
    phase = MatchPhase.running;
    myGoals = matchSteps ~/ stepsPerGoal;
    _halfTimeShown = footballMinute > 45;
    events.add(MatchEventItem(footballMinute, 'Матч продолжается!'));
    _startTimer();
    notifyListeners();
  }

  // Выбор длительности матча на экране настройки матча
  void setDuration(int minutes) {
    if (phase != MatchPhase.idle) return;
    durationMin = minutes;
    notifyListeners();
  }

  // Старт нового матча. Возвращает false, если шагомер не удалось запустить.
  Future<bool> startMatch(int minutes) async {
    // Шагомер должен работать, иначе голы не засчитаются
    if (!_service.isRunning) {
      final started = await _service.start();
      if (!started) return false;
    }

    durationMin = minutes;
    _baseline = _service.todaySteps;
    _startTime = DateTime.now();
    _elapsedSec = 0;
    myGoals = 0;
    oppGoals = 0;
    result = '';
    _halfTimeShown = false;
    _lastAmbientSec = 0;
    events
      ..clear()
      ..add(MatchEventItem(1, _pick(commentaryStart), highlight: true));
    phase = MatchPhase.running;
    _play('whistle.wav'); // стартовый свисток

    await _saveActive();
    _startTimer();
    notifyListeners();
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (phase != MatchPhase.running || _startTime == null) return;

    // Считаем по часам, а не по тикам - так не накапливается ошибка
    _elapsedSec = DateTime.now().difference(_startTime!).inSeconds;

    if (_elapsedSec >= totalSeconds) {
      _finish();
      return;
    }

    // Голы за шаги
    final goalsNow = matchSteps ~/ stepsPerGoal;
    if (goalsNow > myGoals) {
      myGoals = goalsNow;
      _addEvent(_pick(commentaryGoal), highlight: true);
      HapticFeedback.heavyImpact();
      _play('cheer.wav'); // рев трибун
    }

    // Голы соперника: в среднем ~2 за матч, не больше 4
    if (oppGoals < 4 && _rnd.nextDouble() < 2.2 / totalSeconds) {
      oppGoals++;
      _addEvent(_pick(commentaryGoalAgainst), highlight: true);
      _play('ooh.wav'); // разочарованные трибуны
      _prefs?.setInt(_kOppGoals, oppGoals);
    }

    // Перерыв
    if (!_halfTimeShown && footballMinute > 45) {
      _halfTimeShown = true;
      _addEvent(_pick(commentaryHalfTime), highlight: true);
    }

    // Фоновые реплики примерно раз в 4-7 минут
    if (_elapsedSec - _lastAmbientSec > 240 + _rnd.nextInt(180)) {
      _lastAmbientSec = _elapsedSec;
      _addEvent(_pick(commentaryAmbient));
    }

    notifyListeners();
  }

  // Досрочное завершение - результат считается как есть
  Future<void> finishEarly() async => _finish();

  Future<void> _finish() async {
    _timer?.cancel();
    _elapsedSec = totalSeconds;
    myGoals = matchSteps ~/ stepsPerGoal; // финальный пересчёт на всякий случай

    if (myGoals > oppGoals) {
      result = 'win';
    } else if (myGoals == oppGoals) {
      result = 'draw';
    } else {
      result = 'loss';
    }

    final lines = switch (result) {
      'win' => commentaryWin,
      'draw' => commentaryDraw,
      _ => commentaryLoss,
    };
    _addEvent(_pick(lines), highlight: true);
    phase = MatchPhase.finished;
    HapticFeedback.heavyImpact();
    _play('fulltime.wav'); // финальный свисток

    // Обновляем карьерную статистику
    if (_prefs != null) {
      final matches = (_prefs!.getInt(kCareerMatches) ?? 0) + 1;
      final wins = (_prefs!.getInt(kCareerWins) ?? 0) + (result == 'win' ? 1 : 0);
      final goals = (_prefs!.getInt(kCareerGoals) ?? 0) + myGoals;
      final best = max(_prefs!.getInt(kCareerBestGoals) ?? 0, myGoals);
      await _prefs!.setInt(kCareerMatches, matches);
      await _prefs!.setInt(kCareerWins, wins);
      await _prefs!.setInt(kCareerGoals, goals);
      await _prefs!.setInt(kCareerBestGoals, best);
      // Запоминаем дату последнего матча - нужна для ежедневного задания «Игровой день»
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _prefs!.setString(kLastMatchDate, todayKey);
      await _clearActive();
    }
    notifyListeners();
  }

  // Сброс на экран выбора длительности (после просмотра результата)
  void resetToIdle() {
    _timer?.cancel();
    phase = MatchPhase.idle;
    events.clear();
    myGoals = 0;
    oppGoals = 0;
    _elapsedSec = 0;
    result = '';
    notifyListeners();
  }

  Future<void> _saveActive() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_kActive, true);
    await _prefs!.setInt(_kStartMillis, _startTime!.millisecondsSinceEpoch);
    await _prefs!.setInt(_kBaseline, _baseline);
    await _prefs!.setInt(_kDuration, durationMin);
    await _prefs!.setInt(_kOppGoals, oppGoals);
  }

  Future<void> _clearActive() async {
    await _prefs?.setBool(_kActive, false);
  }

  String _pick(List<String> lines) => lines[_rnd.nextInt(lines.length)];

  void _addEvent(String text, {bool highlight = false}) {
    events.insert(0, MatchEventItem(footballMinute, text, highlight: highlight));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    super.dispose();
  }
}
