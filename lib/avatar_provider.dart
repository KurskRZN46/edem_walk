import 'package:flutter/foundation.dart';
import '../data/avatars.dart';
import '../services/storage_service.dart';

// Провайдер выбранного аватара профиля.
// Хранится локально в SharedPreferences, никуда не отправляется.
class AvatarProvider extends ChangeNotifier {
  PlayerAvatar _selected = playerAvatars.first;

  PlayerAvatar get selected => _selected;

  // Загрузка сохранённого аватара при старте приложения
  Future<void> loadAvatar() async {
    final id = await StorageService.getSelectedAvatar();
    _selected = avatarById(id);
    notifyListeners();
  }

  // Выбор нового аватара
  Future<void> selectAvatar(String id) async {
    _selected = avatarById(id);
    await StorageService.saveSelectedAvatar(id);
    notifyListeners();
  }
}
