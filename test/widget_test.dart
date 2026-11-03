// Простые проверки данных приложения (без привязки к железу и БД).
// Старый шаблонный тест "Counter increments smoke test" не соответствовал
// реальному приложению и был заменён.

import 'package:flutter_test/flutter_test.dart';

import 'package:soccer_pedometer_app/data/position_norms.dart';
import 'package:soccer_pedometer_app/data/footballers.dart';

void main() {
  test('Нормативы: 4 позиции, диапазоны корректны', () {
    expect(positionNorms.length, 4);
    for (final p in positionNorms) {
      expect(p.minKm, lessThan(p.maxKm));
      expect(p.targetSteps, greaterThan(0));
    }
  });

  test('Футболисты: у каждого есть статья и факты', () {
    expect(footballers.length, 6);
    for (final f in footballers) {
      expect(f.article, isNotEmpty);
      expect(f.facts, isNotEmpty);
    }
  });

  test('Футболисты: id уникальны и поиск по id работает', () {
    final ids = footballers.map((f) => f.id).toSet();
    expect(ids.length, footballers.length);
    for (final f in footballers) {
      expect(footballerById(f.id)?.name, f.name);
    }
  });
}
