// Данные о футбольных нормативах: сколько километров за матч
// в среднем пробегает игрок каждой позиции.
// Источники цифр - открытая статистика аналитических систем
// (Opta, StatsBomb, данные трансляций): порядок значений общеизвестен.

class PositionNorm {
  final String id; // машинный идентификатор (хранится в SharedPreferences)
  final String name; // "Полузащитник"
  final String nameGenitive; // "полузащитника" (для фразы "Норматив полузащитника")
  final double minKm; // нижняя граница нормы за матч
  final double maxKm; // верхняя граница нормы за матч
  final String description; // короткое пояснение, почему норма такая

  const PositionNorm({
    required this.id,
    required this.name,
    required this.nameGenitive,
    required this.minKm,
    required this.maxKm,
    required this.description,
  });

  // Средняя норма - используем как цель для сравнения с километражом пользователя
  double get targetKm => (minKm + maxKm) / 2;

  // Сколько шагов примерно нужно, чтобы "пробежать матч" на этой позиции.
  // 0.75 м на шаг - та же константа, что и в StepService.km
  int get targetSteps => (targetKm / 0.00075).round();

  String get rangeLabel =>
      '${minKm.toStringAsFixed(1)}–${maxKm.toStringAsFixed(1)} км';
}

// Список позиций в порядке показа на экране
const List<PositionNorm> positionNorms = [
  PositionNorm(
    id: 'goalkeeper',
    name: 'Вратарь',
    nameGenitive: 'вратаря',
    minKm: 4.0,
    maxKm: 5.5,
    description:
        'Меньше всех бегает по полю, но больше всех двигается вратарской '
        'зоне: короткие ускорения, прыжки, выпады. Его километры - про взрывную работу.',
  ),
  PositionNorm(
    id: 'defender',
    name: 'Защитник',
    nameGenitive: 'защитника',
    minKm: 9.0,
    maxKm: 10.5,
    description:
        'Много работы без мяча: догонять нападающих, возвращаться в оборону, '
        'подключаться к атакам по флангу. Основа - среднетемповые отрезки.',
  ),
  PositionNorm(
    id: 'midfielder',
    name: 'Полузащитник',
    nameGenitive: 'полузащитника',
    minKm: 10.5,
    maxKm: 12.5,
    description:
        'Рекордсмены по километражу: работают "от штрафной до штрафной", '
        'связывают оборону и атаку. 11+ км за матч - обычное дело.',
  ),
  PositionNorm(
    id: 'forward',
    name: 'Нападающий',
    nameGenitive: 'нападающего',
    minKm: 9.0,
    maxKm: 11.0,
    description:
        'Меньше "марафонских" отрезков, но максимум спринтов: рывки за защитников, '
        'прессинг, открывания. Километры собираются короткими ускорениями.',
  ),
];

// Поиск позиции по сохранённому id
PositionNorm positionNormById(String id) {
  return positionNorms.firstWhere(
    (p) => p.id == id,
    orElse: () => positionNorms[2], // по умолчанию - полузащитник
  );
}
