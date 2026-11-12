// Ежедневные задания. Обновляются каждый день, прогресс считается
// из текущих данных шагомера - отдельно хранить ничего не нужно.

class DailyQuest {
  final String id;
  final String title;
  final String description;
  final String iconKey;

  const DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
  });
}

const List<DailyQuest> dailyQuests = [
  DailyQuest(
    id: 'steps_6000',
    title: 'Прогулка чемпиона',
    description: 'Пройди 6 000 шагов за день',
    iconKey: 'run',
  ),
  DailyQuest(
    id: 'norm',
    title: 'Норматив дня',
    description: 'Выполни норматив своей позиции (км)',
    iconKey: 'ball',
  ),
  DailyQuest(
    id: 'match',
    title: 'Игровой день',
    description: 'Сыграй хотя бы один матч',
    iconKey: 'whistle',
  ),
];
