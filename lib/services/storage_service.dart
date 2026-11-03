import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/step_data.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _positionKey = 'selected_position_id';
  static const String _stepsBox = 'steps';
  static const String _profileBox = 'profile';

  // Инициализация Hive-боксов
  static Future<void> init() async {
    Hive.registerAdapter(StepDataAdapter());
    await Hive.openBox<StepData>(_stepsBox);
    await Hive.openBox<UserProfile>(_profileBox);
  }

  // Сохраняет ID выбранной футбольной позиции (режим «Нормативы»)
  static Future<void> saveSelectedPosition(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_positionKey, id);
  }

  // Возвращает ID выбранной позиции (по умолчанию - полузащитник)
  static Future<String> getSelectedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_positionKey) ?? 'midfielder';
  }

  // Сохраняет профиль игрока в Hive-бокс
  static Future<void> saveProfile(UserProfile profile) async {
    final box = Hive.box<UserProfile>(_profileBox);
    await box.put('current', profile);
  }

  // Возвращает профиль из Hive
  static UserProfile? getProfile() {
    final box = Hive.box<UserProfile>(_profileBox);
    return box.get('current');
  }

  // Сохраняет шаги за конкретную дату
  static Future<void> saveStepsForDate(StepData data) async {
    final box = Hive.box<StepData>(_stepsBox);
    final key = _dateKey(data.date);
    await box.put(key, data);
  }

  // Возвращает шаги за конкретную дату
  static StepData? getStepsForDate(DateTime date) {
    final box = Hive.box<StepData>(_stepsBox);
    return box.get(_dateKey(date));
  }

  // Возвращает все записи шагов, отсортированные по дате
  static List<StepData> getAllSteps() {
    final box = Hive.box<StepData>(_stepsBox);
    return box.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Полностью очищает историю шагов
  static Future<void> clearHistory() async {
    final box = Hive.box<StepData>(_stepsBox);
    await box.clear();
  }

  // Превращает DateTime в строку 'ГГГГ-ММ-ДД' (ключ для Hive)
  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
