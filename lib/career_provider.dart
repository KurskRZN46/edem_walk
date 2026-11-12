import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/career.dart';
import '../data/league.dart';
import '../services/storage_service.dart';
import 'match_provider.dart';
import 'workout_provider.dart';

// Карьера игрока: ранг по суммарным километрам, статистика матчей,
// разблокированные достижения. Статистика матчей хранится в SharedPreferences
// и пишется MatchProvider при завершении матча; здесь мы её читаем.
class CareerProvider extends ChangeNotifier {
  int matches = 0; // сыграно матчей
  int wins = 0; // побед
  int goals = 0; // голов суммарно
  int bestGoals = 0; // лучший результат за один матч
  String lastMatchDate = ''; // дата последнего матча "yyyy-mm-dd"
  int workoutsDone = 0; // пройдено интервальных тренировок

  // --- Лига недели ---
  static const _kLeagueTier = 'league_tier'; // индекс дивизиона 0..3
  static const _kLeagueWeek = 'league_week'; // понедельник проверенной недели

  int leagueTier = 0; // 0 = Лига 3, 3 = Премьер-лига

  String get leagueName => leagueTiers[leagueTier];

  // Сыгран ли матч сегодня (для ежедневного задания «Игровой день»)
  bool get playedToday {
    if (lastMatchDate.isEmpty) return false;
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return lastMatchDate == todayKey;
  }

  Future<void> init() async {
    await refresh();
  }

  // Перечитать статистику из хранилища (вызывается при открытии экрана карьеры)
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    matches = prefs.getInt(MatchProvider.kCareerMatches) ?? 0;
    wins = prefs.getInt(MatchProvider.kCareerWins) ?? 0;
    goals = prefs.getInt(MatchProvider.kCareerGoals) ?? 0;
    bestGoals = prefs.getInt(MatchProvider.kCareerBestGoals) ?? 0;
    lastMatchDate = prefs.getString(MatchProvider.kLastMatchDate) ?? '';
    workoutsDone = prefs.getInt(WorkoutProvider.kWorkoutsDone) ?? 0;
    leagueTier = prefs.getInt(_kLeagueTier) ?? 0;
    await _evaluateLeagueRollover(prefs);
    notifyListeners();
  }

  // Если с прошлой проверки началась новая неделя - подводим итоги прошлой:
  // топ-2 повышаются в дивизионе, последние двое вылетают
  Future<void> _evaluateLeagueRollover(SharedPreferences prefs) async {
    final thisWeek = weekKey(DateTime.now());
    final checkedWeek = prefs.getString(_kLeagueWeek) ?? thisWeek;
    if (checkedWeek == thisWeek) return;

    // Шаги пользователя за прошлую неделю из истории
    final prevMonday = mondayOf(DateTime.now()).subtract(const Duration(days: 7));
    final thisMonday = mondayOf(DateTime.now());
    var userSteps = 0;
    for (final d in StorageService.getAllSteps()) {
      final day = DateTime(d.date.year, d.date.month, d.date.day);
      if (!day.isBefore(prevMonday) && day.isBefore(thisMonday)) {
        userSteps += d.steps;
      }
    }

    // Итоги ботов за прошлую неделю
    final totals = <int>[
      for (int i = 0; i < leagueBots.length; i++)
        botWeekSteps(i, leagueTier, checkedWeek),
    ];

    // Место пользователя
    final place = 1 + totals.where((b) => b > userSteps).length;
    if (place <= 2 && leagueTier < leagueTiers.length - 1) {
      leagueTier++; // повышение
    } else if (place >= 5 && leagueTier > 0) {
      leagueTier--; // вылет
    }

    await prefs.setInt(_kLeagueTier, leagueTier);
    await prefs.setString(_kLeagueWeek, thisWeek);
  }

  // Текущая таблица лиги. userWeekSteps - шаги пользователя с понедельника.
  // Возвращает отсортированные строки: (имя, шаги, этоПользователь)
  List<({String name, int steps, bool isUser})> leagueStandings(int userWeekSteps) {
    final now = DateTime.now();
    final week = weekKey(now);
    final dayIndex = now.weekday - 1; // 0 = понедельник

    final rows = <({String name, int steps, bool isUser})>[
      (name: 'Ты', steps: userWeekSteps, isUser: true),
      for (int i = 0; i < leagueBots.length; i++)
        (
          name: leagueBots[i].name,
          steps: botStepsByDay(i, leagueTier, week, dayIndex),
          isUser: false,
        ),
    ];
    rows.sort((a, b) => b.steps.compareTo(a.steps));
    return rows;
  }

  // Текущий ранг по суммарному километражу
  CareerRank rankFor(double totalKm) => rankForKm(totalKm);

  // Список достижений с флагом "разблокировано".
  // Параметры приходят из StepProvider, чтобы провайдеры не сцеплялись.
  List<({Achievement achievement, bool unlocked})> achievements({
    required int totalSteps,
    required int bestDaySteps,
    required int streakDays,
    required double totalKm,
    int workouts = -1, // -1 = взять из хранилища (this.workoutsDone)
  }) {
    final done = workouts >= 0 ? workouts : workoutsDone;
    bool isUnlocked(String id) {
      switch (id) {
        case 'first_steps':
          return totalSteps >= 1000;
        case 'debut':
          return matches >= 1;
        case 'first_win':
          return wins >= 1;
        case 'hat_trick':
          return bestGoals >= 3;
        case 'sniper':
          return goals >= 10;
        case 'marathon':
          // 20 км за день: 20 / 0.00075 = 26667 шагов
          return bestDaySteps >= 26667;
        case 'week_streak':
          return streakDays >= 7;
        case 'iron':
          return streakDays >= 30;
        case 'hundred':
          return totalKm >= 100;
        case 'legend':
          return totalKm >= 250;
        case 'first_workout':
          return done >= 1;
        case 'training_machine':
          return done >= 10;
        default:
          return false;
      }
    }

    return allAchievements
        .map((a) => (achievement: a, unlocked: isUnlocked(a.id)))
        .toList();
  }

  // Сколько достижений разблокировано
  int unlockedCount({
    required int totalSteps,
    required int bestDaySteps,
    required int streakDays,
    required double totalKm,
  }) {
    return achievements(
      totalSteps: totalSteps,
      bestDaySteps: bestDaySteps,
      streakDays: streakDays,
      totalKm: totalKm,
    ).where((e) => e.unlocked).length;
  }
}
