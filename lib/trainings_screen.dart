import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/training_plans.dart';
import '../data/exercises.dart';
import '../providers/normative_provider.dart';
import '../providers/step_provider.dart';
import '../providers/workout_provider.dart';
import 'workout_screen.dart';

// Экран «План тренировок»: недельная программа под выбранную позицию.
// Сегодняшний день подсвечен, прогресс дня считается по шагам.
class TrainingsScreen extends StatelessWidget {
  const TrainingsScreen({super.key});

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final norm = context.watch<NormativeProvider>().selected;
    final steps = context.watch<StepProvider>().steps;
    final wp = context.watch<WorkoutProvider>(); // сложность, отметки дней
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    final plan = trainingPlanFor(norm.id);
    final todayIndex = DateTime.now().weekday - 1; // 0 = понедельник

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _TrainingsHeader(isDark: isDark, theme: theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Шапка: для какой позиции план
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center, color: red, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'План ${norm.nameGenitive}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Меняется автоматически при смене позиции в «Нормативах»',
                                style: TextStyle(fontSize: 11.5, color: subColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Большая кнопка интервальной тренировки
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'Интервальная тренировка',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Приложение ведёт по фазам: разминка, рывки, заминка',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: subColor),
                  ),
                  const SizedBox(height: 16),
                  // Сложность плана
                  Text(
                    'Сложность плана',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int level = 0; level < 3; level++) ...[
                        if (level > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => wp.setDifficulty(level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: wp.planDifficulty == level
                                    ? green
                                    : cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: wp.planDifficulty == level
                                      ? green
                                      : borderColor,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    WorkoutProvider.difficultyNames[level],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: wp.planDifficulty == level
                                          ? Colors.white
                                          : textColor,
                                    ),
                                  ),
                                  Text(
                                    '×${[0.8, 1.0, 1.3][level]}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: wp.planDifficulty == level
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Прогресс недели по отметкам
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Выполнено за неделю: ${wp.weekDoneCount} из 7',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Icon(
                              wp.weekDoneCount == 7
                                  ? Icons.emoji_events
                                  : Icons.checklist,
                              size: 18,
                              color: wp.weekDoneCount == 7 ? green : subColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: wp.weekDoneCount / 7,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? const Color(0xFF1E2730)
                                : const Color(0xFFE8ECF1),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(green),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Отмечай дни галочкой, когда выполнил норму',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Дни недели
                  for (int i = 0; i < 7; i++) ...[
                    Builder(builder: (context) {
                      final day = plan.days[i];
                      final target = wp.scaledSteps(day.steps); // цель с учётом сложности
                      final isToday = i == todayIndex;
                      final isPast = i < todayIndex;
                      final isDone = wp.isDayDone(i);
                      final progress =
                          isToday ? (steps / target).clamp(0.0, 1.0) : (isPast ? 1.0 : 0.0);
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isToday
                              ? green.withValues(alpha: isDark ? 0.15 : 0.08)
                              : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isToday ? green : borderColor,
                            width: isToday ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // День недели
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? green
                                    : isPast
                                        ? green.withValues(alpha: 0.2)
                                        : (isDark
                                            ? const Color(0xFF1E2730)
                                            : const Color(0xFFE8ECF1)),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _weekdays[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isToday ? Colors.white : textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          day.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(target / 1000).toStringAsFixed(target % 1000 == 0 ? 0 : 1)}K шагов',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isToday ? green : subColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    day.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: subColor,
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: isDark
                                            ? const Color(0xFF1E2730)
                                            : const Color(0xFFE8ECF1),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                green),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Сегодня: $steps / $target',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: green,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Галочка "день выполнен"
                            GestureDetector(
                              onTap: () => wp.toggleDayDone(i),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDone ? green : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDone ? green : borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 18,
                                  color: isDone ? Colors.white : subColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 18),
                  // Библиотека упражнений
                  _ExercisesSection(
                    title: 'Разминка перед тренировкой',
                    icon: Icons.whatshot,
                    iconColor: const Color(0xFFFFB300),
                    items: warmupExercises,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _ExercisesSection(
                    title: 'Заминка и растяжка',
                    icon: Icons.self_improvement,
                    iconColor: const Color(0xFF7E57C2),
                    items: stretchExercises,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Секция упражнений (разминка или заминка)
class _ExercisesSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Exercise> items;
  final bool isDark;

  const _ExercisesSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Text(
                              e.dose,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.description,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Хедер экрана тренировок
class _TrainingsHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _TrainingsHeader({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF1744);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B23) : const Color(0xFFE8ECF1),
        border: Border(
          bottom: BorderSide(color: red.withValues(alpha: 0.6), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: red.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'План тренировок',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0.3,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
