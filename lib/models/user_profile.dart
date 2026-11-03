import 'package:hive/hive.dart';

// Тут сгенерированный код, который умеет сохранять UserProfile в базу (т.е. переводить его в байты) и читать обратно
part 'user_profile.g.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String avatar;

  @HiveField(2)
  final int dailyGoal;

  UserProfile({
    required this.name,
    this.avatar = 'default',
    this.dailyGoal = 10000,
  });
}
