// Интервальные тренировки: готовые программы с фазами по времени.
// Каждая фаза - это отрезок со своим темпом. Приложение ведёт по фазам,
// свистит на смене и считает шаги за тренировку.

// Виды фаз (от вида зависит цвет и иконка на экране)
enum WorkoutPhaseKind { warmup, fast, sprint, easy, cooldown }

// Одна фаза тренировки
class WorkoutPhase {
  final WorkoutPhaseKind kind;
  final String title; // что показываем крупно ("Быстрый темп!")
  final String hint; // подсказка, что делать
  final int seconds; // длительность

  const WorkoutPhase({
    required this.kind,
    required this.title,
    required this.hint,
    required this.seconds,
  });
}

// Готовая интервальная тренировка
class IntervalWorkout {
  final String id;
  final String name;
  final String tagline; // короткое описание
  final String difficulty; // "Лёгкая" / "Средняя" / "Жёсткая"
  final int difficultyLevel; // 1..3 для цветных чипсов
  final List<WorkoutPhase> phases;

  const IntervalWorkout({
    required this.id,
    required this.name,
    required this.tagline,
    required this.difficulty,
    required this.difficultyLevel,
    required this.phases,
  });

  // Общая длительность в секундах
  int get totalSeconds => phases.fold(0, (sum, p) => sum + p.seconds);

  // Длительность в минутах (для подписи на карточке)
  int get totalMinutes => (totalSeconds / 60).round();
}

// Удобные конструкторы фаз
WorkoutPhase _warmup(int sec) => WorkoutPhase(
      kind: WorkoutPhaseKind.warmup,
      title: 'Разминка',
      hint: 'Спокойная ходьба, разомни суставы круговыми движениями',
      seconds: sec,
    );

WorkoutPhase _fast(int sec) => WorkoutPhase(
      kind: WorkoutPhaseKind.fast,
      title: 'Быстрый темп!',
      hint: 'Иди быстро, как будто опаздываешь на тренировку',
      seconds: sec,
    );

WorkoutPhase _sprint(int sec) => WorkoutPhase(
      kind: WorkoutPhaseKind.sprint,
      title: 'Рывок!',
      hint: 'Максимальный темп! Короткие частые шаги, работай руками',
      seconds: sec,
    );

WorkoutPhase _easy(int sec) => WorkoutPhase(
      kind: WorkoutPhaseKind.easy,
      title: 'Восстановление',
      hint: 'Спокойный шаг, восстанови дыхание',
      seconds: sec,
    );

WorkoutPhase _cooldown(int sec) => WorkoutPhase(
      kind: WorkoutPhaseKind.cooldown,
      title: 'Заминка',
      hint: 'Медленный шаг, дыхание восстанавливается. Молодец!',
      seconds: sec,
    );

// Библиотека тренировок
final List<IntervalWorkout> intervalWorkouts = [
  IntervalWorkout(
    id: 'champion_warmup',
    name: 'Разминка чемпиона',
    tagline: 'Мягкий старт дня: разогреться и зарядиться',
    difficulty: 'Лёгкая',
    difficultyLevel: 1,
    phases: [
      _warmup(120), // 2 мин
      _fast(180), // 3 мин
      _easy(120), // 2 мин
      _fast(120), // 2 мин
      _cooldown(60), // 1 мин
    ],
  ),
  IntervalWorkout(
    id: 'midfield_intervals',
    name: 'Интервалы полузащитника',
    tagline: 'Классика футбольной подготовки: 5 ускорений',
    difficulty: 'Средняя',
    difficultyLevel: 2,
    phases: [
      _warmup(180), // 3 мин
      for (int i = 0; i < 5; i++) ...[
        _fast(120), // 2 мин быстро
        _easy(60), // 1 мин спокойно
      ],
      _cooldown(120), // 2 мин
    ],
  ),
  IntervalWorkout(
    id: 'striker_sprints',
    name: 'Спринт-сессия нападающего',
    tagline: '6 взрывных рывков - как выход один на один',
    difficulty: 'Жёсткая',
    difficultyLevel: 3,
    phases: [
      _warmup(180), // 3 мин
      for (int i = 0; i < 6; i++) ...[
        _sprint(60), // 1 мин максимум
        _easy(60), // 1 мин восстановление
      ],
      _cooldown(120), // 2 мин
    ],
  ),
  IntervalWorkout(
    id: 'defender_tempo',
    name: 'Выносливость защитника',
    tagline: 'Длинная равномерная работа - база на 90 минут',
    difficulty: 'Средняя',
    difficultyLevel: 2,
    phases: [
      _warmup(180), // 3 мин
      WorkoutPhase(
        kind: WorkoutPhaseKind.fast,
        title: 'Темповая работа',
        hint: 'Ровный бодрый шаг без пауз. Дыши носом, если получается',
        seconds: 1380, // 23 мин
      ),
      _cooldown(240), // 4 мин
    ],
  ),
];

// Тренировка по id (первая, если не нашли)
IntervalWorkout workoutById(String id) {
  for (final w in intervalWorkouts) {
    if (w.id == id) return w;
  }
  return intervalWorkouts.first;
}
