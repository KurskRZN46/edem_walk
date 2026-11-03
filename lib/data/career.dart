// Данные карьеры: ранги игрока, достижения, города-маршруты.
// Чистые данные без логики UI: иконки задаются ключом, маппинг - на экране.

// Ранг карьеры. Повышается от суммарного километража за всё время.
class CareerRank {
  final String id;
  final String name; // название ранга
  final double minKm; // порог в километрах (суммарно за всё время)
  final String motto; // короткая мотивационная подпись
  final String iconKey; // ключ иконки, маппится в UI

  const CareerRank({
    required this.id,
    required this.name,
    required this.minKm,
    required this.motto,
    required this.iconKey,
  });
}

// Ранги по суммарным километрам. От простого к крутому.
const List<CareerRank> careerRanks = [
  CareerRank(
    id: 'amateur',
    name: 'Любитель',
    minKm: 0,
    motto: 'Каждая легенда начинала с первого шага',
    iconKey: 'boot',
  ),
  CareerRank(
    id: 'reserve',
    name: 'Дубль',
    minKm: 20,
    motto: 'Тебя заметили тренеры. Продолжай',
    iconKey: 'shirt',
  ),
  CareerRank(
    id: 'main',
    name: 'Основа',
    minKm: 50,
    motto: 'Ты в стартовом составе',
    iconKey: 'ball',
  ),
  CareerRank(
    id: 'captain',
    name: 'Капитан',
    minKm: 120,
    motto: 'Команда идёт за тобой',
    iconKey: 'band',
  ),
  CareerRank(
    id: 'legend',
    name: 'Легенда',
    minKm: 250,
    motto: 'Твоё имя знает весь стадион',
    iconKey: 'crown',
  ),
];

// Текущий ранг по километражу
CareerRank rankForKm(double km) {
  var current = careerRanks.first;
  for (final r in careerRanks) {
    if (km >= r.minKm) current = r;
  }
  return current;
}

// Следующий ранг (null, если уже Легенда)
CareerRank? nextRankForKm(double km) {
  for (final r in careerRanks) {
    if (km < r.minKm) return r;
  }
  return null;
}

// Прогресс до следующего ранга: 0.0 - 1.0 (1.0, если ранг максимальный)
double rankProgress(double km) {
  final current = rankForKm(km);
  final next = nextRankForKm(km);
  if (next == null) return 1.0;
  final span = next.minKm - current.minKm;
  if (span <= 0) return 1.0;
  return ((km - current.minKm) / span).clamp(0.0, 1.0);
}

// Описание достижения (шаблон, без состояния)
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconKey;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
  });
}

// Все достижения приложения
const List<Achievement> allAchievements = [
  Achievement(
    id: 'first_steps',
    title: 'Первые шаги',
    description: 'Пройти 1 000 шагов суммарно',
    iconKey: 'boot',
  ),
  Achievement(
    id: 'debut',
    title: 'Дебют',
    description: 'Сыграть первый матч',
    iconKey: 'whistle',
  ),
  Achievement(
    id: 'first_win',
    title: 'Первая победа',
    description: 'Выиграть матч',
    iconKey: 'cup',
  ),
  Achievement(
    id: 'hat_trick',
    title: 'Хет-трик',
    description: 'Забить 3+ гола в одном матче',
    iconKey: 'ball',
  ),
  Achievement(
    id: 'sniper',
    title: 'Снайпер',
    description: '10 голов суммарно в матчах',
    iconKey: 'target',
  ),
  Achievement(
    id: 'marathon',
    title: 'Марафонец',
    description: '20 км за один день',
    iconKey: 'run',
  ),
  Achievement(
    id: 'week_streak',
    title: 'Серия недели',
    description: '7 дней подряд с активностью',
    iconKey: 'fire',
  ),
  Achievement(
    id: 'iron',
    title: 'Железный',
    description: '30 дней подряд с активностью',
    iconKey: 'shield',
  ),
  Achievement(
    id: 'hundred',
    title: 'Сотня',
    description: '100 км суммарно',
    iconKey: 'road',
  ),
  Achievement(
    id: 'legend',
    title: 'Легенда',
    description: 'Достичь ранга «Легенда» (250 км)',
    iconKey: 'crown',
  ),
  Achievement(
    id: 'first_workout',
    title: 'Первая тренировка',
    description: 'Пройти интервальную тренировку',
    iconKey: 'fitness',
  ),
  Achievement(
    id: 'training_machine',
    title: 'Машина',
    description: 'Пройти 10 интервальных тренировок',
    iconKey: 'engine',
  ),
];

// Города-маршруты: "ты уже дошёл от Курска до...".
// Расстояния примерные (по прямой), это мотивационная фишка, а не навигатор.
class CityMilestone {
  final String city;
  final int km;

  const CityMilestone(this.city, this.km);
}

const List<CityMilestone> cityMilestones = [
  CityMilestone('Первый марафон', 42),
  CityMilestone('Белгород', 140),
  CityMilestone('Воронеж', 220),
  CityMilestone('Москва', 530),
  CityMilestone('Казань', 1000),
  CityMilestone('Санкт-Петербург', 1100),
  CityMilestone('Сочи', 1350),
  CityMilestone('Лиссабон', 4500),
];

// Следующий непройденный город (null, если все пройдены)
CityMilestone? nextMilestone(double totalKm) {
  for (final m in cityMilestones) {
    if (totalKm < m.km) return m;
  }
  return null;
}

// Уже пройденные города
List<CityMilestone> reachedMilestones(double totalKm) {
  return cityMilestones.where((m) => totalKm >= m.km).toList();
}
