// Библиотека упражнений: разминка перед тренировкой и заминка (растяжка)
// после. Текстовые карточки - без видео, чтобы приложение оставалось лёгким.

class Exercise {
  final String name; // название
  final String description; // как делать
  final String dose; // дозировка: "30 сек", "2 подхода по 10"
  final String zone; // 'warmup' - разминка, 'stretch' - заминка

  const Exercise({
    required this.name,
    required this.description,
    required this.dose,
    required this.zone,
  });
}

const List<Exercise> exercises = [
  // --- РАЗМИНКА ---
  Exercise(
    name: 'Подъёмы коленей',
    description:
        'Ходи на месте, высоко поднимая колени до уровня пояса. Руки работают как при беге.',
    dose: '40 секунд',
    zone: 'warmup',
  ),
  Exercise(
    name: 'Захлёсты голенью',
    description:
        'Ходьба на месте: пяткой старайся коснуться ягодиц. Разогревает колени и бёдра.',
    dose: '40 секунд',
    zone: 'warmup',
  ),
  Exercise(
    name: 'Круги тазом',
    description:
        'Руки на поясе, делай большие круги тазом в обе стороны. Мягко и без рывков.',
    dose: '30 секунд в каждую сторону',
    zone: 'warmup',
  ),
  Exercise(
    name: 'Выпады вперёд',
    description:
        'Шаг вперёд, присядь на переднюю ногу до прямого угла в колене, вернись. Чередуй ноги.',
    dose: '2 подхода по 8 на ногу',
    zone: 'warmup',
  ),
  Exercise(
    name: 'Приставные шаги',
    description:
        'Двигайся боком: приставляй ногу к ноге, как защитник, сопровождающий соперника.',
    dose: '30 секунд в каждую сторону',
    zone: 'warmup',
  ),
  Exercise(
    name: 'Вращения корпусом',
    description:
        'Ноги на ширине плеч, руки согнуты перед грудью. Поворачивай корпус влево-вправо.',
    dose: '40 секунд',
    zone: 'warmup',
  ),
  // --- ЗАМИНКА (РАСТЯЖКА) ---
  Exercise(
    name: 'Задняя поверхность бедра',
    description:
        'Нога прямая на возвышении (бордюр, скамья), наклоняйся к носку. Без пружинящих движений.',
    dose: '30 секунд на ногу',
    zone: 'stretch',
  ),
  Exercise(
    name: 'Квадрицепс стоя',
    description:
        'Стоя на одной ноге, согни вторую и прижми пятку к ягодице. Держись за опору.',
    dose: '30 секунд на ногу',
    zone: 'stretch',
  ),
  Exercise(
    name: 'Икры у стены',
    description:
        'Руки в стену, одна нога сзади с прямым коленом, пятка на полу. Дави пяткой в пол.',
    dose: '30 секунд на ногу',
    zone: 'stretch',
  ),
  Exercise(
    name: 'Наклон к стопам',
    description:
        'Сядь, ноги прямые. Медленно тянись руками к носкам, спина прямая. Дыши.',
    dose: '40 секунд',
    zone: 'stretch',
  ),
  Exercise(
    name: 'Бабочка',
    description:
        'Сидя, соедини стопы, колени в стороны. Мягко дави локтями на колени.',
    dose: '40 секунд',
    zone: 'stretch',
  ),
  Exercise(
    name: 'Вращения стоп',
    description:
        'Сидя или стоя, вращай стопой по кругу. Восстановление после долгой ходьбы.',
    dose: '30 секунд на ногу',
    zone: 'stretch',
  ),
];

// Разминка (перед тренировкой)
List<Exercise> get warmupExercises =>
    exercises.where((e) => e.zone == 'warmup').toList();

// Заминка (после тренировки)
List<Exercise> get stretchExercises =>
    exercises.where((e) => e.zone == 'stretch').toList();
