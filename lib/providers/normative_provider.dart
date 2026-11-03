import 'package:flutter/foundation.dart';
import '../data/position_norms.dart';
import '../services/storage_service.dart';

// Провайдер выбранной футбольной позиции для режима «Нормативы футболиста».
// ChangeNotifier умеет уведомлять подписчиков: когда пользователь меняет позицию,
// все виджеты с context.watch<NormativeProvider>() перерисовываются.
class NormativeProvider extends ChangeNotifier {
  PositionNorm _selected = positionNorms[2]; // по умолчанию - полузащитник

  PositionNorm get selected => _selected;

  // Загрузка сохранённой позиции при старте приложения (вызывается из main.dart)
  Future<void> loadPosition() async {
    final id = await StorageService.getSelectedPosition();
    _selected = positionNormById(id);
    notifyListeners();
  }

  // Выбор новой позиции. Вызывается из normatives_screen.dart
  Future<void> selectPosition(PositionNorm norm) async {
    _selected = norm;
    await StorageService.saveSelectedPosition(norm.id);
    notifyListeners();
  }
}
