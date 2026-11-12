import 'package:hive/hive.dart';

// Тут сгенерированный код, который умеет сохранять StepData в базу (т.е. переводить его в байты) и читать обратно
part 'step_data.g.dart';

@HiveType(typeId: 0)
class StepData extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  int steps;

  @HiveField(2)
  int goal;

  StepData({
    required this.date,
    this.steps = 0,
    this.goal = 10000,
  });

  double get progress => goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;

  bool get isGoalReached => steps >= goal;
}
