import 'dart:math';

// Лига недели: соревнование с 5 виртуальными клубами.
// Всё локально и детерминировано: боты "ходят" предсказуемо
// (seed = номер недели), поэтому таблица одинакова весь день
// и не требует сервера.

class LeagueBot {
  final String name;
  final int weeklyBase; // база шагов за неделю (в Лиге 3)

  const LeagueBot(this.name, this.weeklyBase);
}

// Вымышленные клубы-соперники
const List<LeagueBot> leagueBots = [
  LeagueBot('ФК Молния', 52000),
  LeagueBot('Динамо Сити', 46000),
  LeagueBot('Атлетик Юг', 60000),
  LeagueBot('Северная Звезда', 41000),
  LeagueBot('Торпедо-2000', 68000),
];

// Дивизионы от низшего к высшему
const List<String> leagueTiers = ['Лига 3', 'Лига 2', 'Лига 1', 'Премьер-лига'];

// Понедельник текущей недели (начало игровой недели)
DateTime mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

// Ключ недели для хранилища: "2026-11-02" (понедельник)
String weekKey(DateTime date) {
  final m = mondayOf(date);
  return '${m.year}-${m.month.toString().padLeft(2, '0')}-${m.day.toString().padLeft(2, '0')}';
}

// Seed недели для генератора случайности
int weekSeed(String key) {
  var h = 0;
  for (final c in key.codeUnits) {
    h = h * 31 + c;
  }
  return h;
}

// Итог бота за полную неделю (детерминировано по неделе и дивизиону)
int botWeekSteps(int botIndex, int tier, String week) {
  final rnd = Random(weekSeed(week) * 31 + botIndex * 7 + 13);
  final jitter = 0.85 + rnd.nextDouble() * 0.3; // 0.85 - 1.15
  final tierBoost = 1 + tier * 0.18; // выше дивизион - сильнее боты
  return (leagueBots[botIndex].weeklyBase * tierBoost * jitter).round();
}

// Накопленные шаги бота к концу указанного дня недели (0 - пн, 6 - вс)
int botStepsByDay(int botIndex, int tier, String week, int dayIndex) {
  // Профиль недели: в будни меньше, в выходные больше
  const weights = [0.11, 0.13, 0.13, 0.14, 0.15, 0.18, 0.16];
  final total = botWeekSteps(botIndex, tier, week);
  final rnd = Random(weekSeed(week) + botIndex * 101);
  var sum = 0.0;
  for (int d = 0; d <= dayIndex && d < 7; d++) {
    final dayJitter = 0.7 + rnd.nextDouble() * 0.6; // 0.7 - 1.3
    sum += weights[d] * total * dayJitter;
  }
  return sum.round();
}
