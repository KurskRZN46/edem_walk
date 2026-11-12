// Простые проверки данных приложения (без привязки к железу и БД).
// Старый шаблонный тест "Counter increments smoke test" не соответствовал
// реальному приложению и был заменён.

import 'package:flutter_test/flutter_test.dart';

import 'package:soccer_pedometer_app/data/position_norms.dart';
import 'package:soccer_pedometer_app/data/footballers.dart';
import 'package:soccer_pedometer_app/data/career.dart';
import 'package:soccer_pedometer_app/data/football_facts.dart';
import 'package:soccer_pedometer_app/data/football_quiz.dart';
import 'package:soccer_pedometer_app/data/avatars.dart';
import 'package:soccer_pedometer_app/data/league.dart';
import 'package:soccer_pedometer_app/data/training_plans.dart';
import 'package:soccer_pedometer_app/data/workouts.dart';
import 'package:soccer_pedometer_app/data/exercises.dart';

void main() {
  test('Нормативы: 4 позиции, диапазоны корректны', () {
    expect(positionNorms.length, 4);
    for (final p in positionNorms) {
      expect(p.minKm, lessThan(p.maxKm));
      expect(p.targetSteps, greaterThan(0));
    }
  });

  test('Футболисты: у каждого есть статья и факты', () {
    expect(footballers.length, 15);
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

  test('Карьера: ранги идут по возрастанию порогов', () {
    for (int i = 1; i < careerRanks.length; i++) {
      expect(careerRanks[i].minKm, greaterThan(careerRanks[i - 1].minKm));
    }
    // 0 км -> Любитель, 60 км -> Основа, 1000 км -> Легенда
    expect(rankForKm(0).id, 'amateur');
    expect(rankForKm(60).id, 'main');
    expect(rankForKm(1000).id, 'legend');
    // У Легенды нет следующего ранга
    expect(nextRankForKm(1000), isNull);
    expect(rankProgress(1000), 1.0);
  });

  test('Города-маршруты: отсортированы, следующий город считается верно', () {
    for (int i = 1; i < cityMilestones.length; i++) {
      expect(cityMilestones[i].km, greaterThan(cityMilestones[i - 1].km));
    }
    expect(nextMilestone(0)?.city, 'Первый марафон');
    expect(nextMilestone(600)?.city, 'Казань');
    expect(nextMilestone(99999), isNull); // все пройдены
  });

  test('Мир футбола: факты, термины, рекорды, история не пустые', () {
    expect(footballFacts.length, greaterThanOrEqualTo(31)); // минимум на месяц
    expect(factOfTheDay(), isNotEmpty);
    for (final t in footballTerms) {
      expect(t.term, isNotEmpty);
      expect(t.definition, isNotEmpty);
    }
    for (final r in footballRecords) {
      expect(r.holder, isNotEmpty);
    }
    for (final h in footballHistory) {
      expect(h.year, isNotEmpty);
    }
  });

  test('Викторина: у каждого вопроса 4 варианта и корректный индекс', () {
    expect(footballQuiz.length, greaterThanOrEqualTo(20));
    for (final q in footballQuiz) {
      expect(q.options.length, 4);
      expect(q.correctIndex, inInclusiveRange(0, 3));
    }
  });

  test('Аватары: 8 штук, id уникальны, поиск по id работает', () {
    expect(playerAvatars.length, 8);
    final ids = playerAvatars.map((a) => a.id).toSet();
    expect(ids.length, playerAvatars.length);
    expect(avatarById('unknown_id').id, playerAvatars.first.id); // fallback
  });

  test('Лига: боты детерминированы и растут по дням недели', () {
    final week = weekKey(DateTime.now());
    // Один и тот же запрос - один и тот же результат
    expect(botWeekSteps(0, 0, week), botWeekSteps(0, 0, week));
    // Шаги накапливаются: воскресенье >= понедельника
    expect(botStepsByDay(0, 0, week, 6), greaterThan(botStepsByDay(0, 0, week, 0)));
    // Выше дивизион - сильнее боты
    expect(botWeekSteps(0, 3, week), greaterThan(botWeekSteps(0, 0, week) ~/ 1.2));
    // Понедельник - начало недели
    expect(mondayOf(DateTime(2026, 11, 4)).weekday, 1);
  });

  test('Энциклопедия: новые разделы заполнены', () {
    expect(footballStadiums.length, greaterThanOrEqualTo(8));
    expect(footballTactics.length, greaterThanOrEqualTo(8));
    expect(legendaryClubs.length, greaterThanOrEqualTo(8));
  });

  test('Планы тренировок: 4 позиции, по 7 дней, цели в шагах > 0', () {
    expect(trainingPlans.length, 4);
    for (final plan in trainingPlans) {
      expect(plan.days.length, 7);
      for (final d in plan.days) {
        expect(d.steps, greaterThan(0));
        expect(d.description, isNotEmpty);
      }
    }
    // Fallback на полузащитника
    expect(trainingPlanFor('unknown').positionId, 'midfielder');
  });

  test('Интервальные тренировки: начинаются с разминки, заканчиваются заминкой', () {
    expect(intervalWorkouts.length, greaterThanOrEqualTo(4));
    for (final w in intervalWorkouts) {
      expect(w.totalSeconds, greaterThan(0));
      expect(w.totalMinutes, greaterThan(0));
      // Безопасная структура: разминка в начале, заминка в конце
      expect(w.phases.first.kind, WorkoutPhaseKind.warmup);
      expect(w.phases.last.kind, WorkoutPhaseKind.cooldown);
      // У каждой фазы есть время и подсказка
      for (final p in w.phases) {
        expect(p.seconds, greaterThan(0));
        expect(p.hint, isNotEmpty);
      }
    }
    // Fallback на первую тренировку
    expect(workoutById('unknown').id, intervalWorkouts.first.id);
  });

  test('Упражнения: заполнены разминка и заминка', () {
    expect(warmupExercises.length, greaterThanOrEqualTo(5));
    expect(stretchExercises.length, greaterThanOrEqualTo(5));
    for (final e in exercises) {
      expect(e.description, isNotEmpty);
      expect(e.dose, isNotEmpty);
    }
  });  test('v12: контент расширен - объёмы разделов', () {
    expect(footballers.length, 15);
    expect(footballFacts.length, greaterThanOrEqualTo(80));
    expect(footballStadiums.length, greaterThanOrEqualTo(14));
    expect(footballTactics.length, greaterThanOrEqualTo(12));
    expect(legendaryClubs.length, greaterThanOrEqualTo(16));
    expect(footballTerms.length, greaterThanOrEqualTo(30));
    expect(footballRecords.length, greaterThanOrEqualTo(18));
    expect(footballHistory.length, greaterThanOrEqualTo(18));
  });
}
