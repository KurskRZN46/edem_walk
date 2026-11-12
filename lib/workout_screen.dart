import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/workouts.dart';
import '../providers/workout_provider.dart';
import '../providers/step_provider.dart';
import '../services/step_service.dart' show PermissionState;

// Экран «Тренировка»: интервальные программы с ведением по фазам.
// Свисток на смене темпа, живой счёт шагов и калорий за тренировку.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _WorkoutHeader(
              isDark: isDark,
              theme: theme,
              showBack: wp.state != WorkoutState.running,
            ),
            Expanded(
              child: switch (wp.state) {
                WorkoutState.idle => _IdleView(isDark: isDark),
                WorkoutState.running => _RunningView(isDark: isDark),
                WorkoutState.finished => _FinishedView(isDark: isDark),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Цвет и иконка фазы по её виду
Color phaseColor(WorkoutPhaseKind kind) => switch (kind) {
      WorkoutPhaseKind.warmup => const Color(0xFFFFB300),
      WorkoutPhaseKind.fast => const Color(0xFF00C853),
      WorkoutPhaseKind.sprint => const Color(0xFFFF1744),
      WorkoutPhaseKind.easy => const Color(0xFF0091EA),
      WorkoutPhaseKind.cooldown => const Color(0xFF7E57C2),
    };

IconData phaseIcon(WorkoutPhaseKind kind) => switch (kind) {
      WorkoutPhaseKind.warmup => Icons.whatshot,
      WorkoutPhaseKind.fast => Icons.directions_run,
      WorkoutPhaseKind.sprint => Icons.bolt,
      WorkoutPhaseKind.easy => Icons.directions_walk,
      WorkoutPhaseKind.cooldown => Icons.self_improvement,
    };

// Формат времени мм:сс
String fmtTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

// Хедер экрана тренировки
class _WorkoutHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final bool showBack;

  const _WorkoutHeader({
    required this.isDark,
    required this.theme,
    required this.showBack,
  });

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
          if (showBack)
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  size: 18,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 48),
          const Icon(Icons.fitness_center, color: red, size: 20),
          const SizedBox(width: 8),
          Text(
            'Тренировка',
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

// Список тренировок + статистика
class _IdleView extends StatelessWidget {
  final bool isDark;
  const _IdleView({required this.isDark});

  Color _difficultyColor(int level) => switch (level) {
        1 => const Color(0xFF00C853),
        2 => const Color(0xFFFFB300),
        _ => const Color(0xFFFF1744),
      };

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    const green = Color(0xFF00C853);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Статистика тренировок
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                icon: Icons.fitness_center,
                value: '${wp.workoutsDone}',
                label: 'тренировок',
                color: green,
                textColor: textColor,
                subColor: subColor,
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: borderColor),
              _StatChip(
                icon: Icons.timer,
                value: '${wp.totalSeconds ~/ 60}',
                label: 'минут всего',
                color: const Color(0xFF0091EA),
                textColor: textColor,
                subColor: subColor,
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: borderColor),
              _StatChip(
                icon: Icons.local_fire_department,
                value: '${(wp.totalSeconds / 60 * 5).round()}',
                label: 'ккал примерно',
                color: const Color(0xFFFF1744),
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Выбери программу',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Приложение ведёт тебя по фазам и свистит на смене темпа',
          style: TextStyle(fontSize: 12, color: subColor),
        ),
        const SizedBox(height: 12),
        // Карточки тренировок
        for (final w in intervalWorkouts)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _startWorkout(context, w),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              w.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                          ),
                          // Чип сложности
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _difficultyColor(w.difficultyLevel)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              w.difficulty,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _difficultyColor(w.difficultyLevel),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        w.tagline,
                        style: TextStyle(fontSize: 12.5, color: subColor, height: 1.35),
                      ),
                      const SizedBox(height: 10),
                      // Полоса фаз: пропорции по времени, цвет по виду
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            for (final p in w.phases)
                              Expanded(
                                flex: p.seconds,
                                child: Container(
                                  height: 8,
                                  color: phaseColor(p.kind),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 15, color: subColor),
                          const SizedBox(width: 4),
                          Text(
                            '${w.totalMinutes} мин · ${w.phases.length} фаз',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: subColor,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.play_circle_fill,
                              size: 28, color: green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Запуск тренировки с проверкой разрешения (как в режиме «Матч»)
  Future<void> _startWorkout(BuildContext context, IntervalWorkout w) async {
    HapticFeedback.mediumImpact();
    final wp = context.read<WorkoutProvider>();
    final stepProvider = context.read<StepProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final started = await wp.start(w);
    if (!started) {
      final permanently =
          stepProvider.permissionState == PermissionState.permanentlyDenied;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            permanently
                ? 'Нет доступа к датчику шагов. Разрешите его в настройках телефона'
                : 'Для тренировки нужен запущенный шагомер — разрешите доступ к активности',
          ),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: () => stepProvider.openSystemSettings(),
          ),
        ),
      );
    }
  }
}

// Маленькая статистика (иконка + значение + подпись)
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textColor;
  final Color subColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10.5, color: subColor)),
      ],
    );
  }
}

// Идущая тренировка: кольцо фазы, подсказки, живые шаги
class _RunningView extends StatelessWidget {
  final bool isDark;
  const _RunningView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    final phase = wp.currentPhase;
    final next = wp.nextPhase;
    final w = wp.workout;
    if (phase == null || w == null) return const SizedBox.shrink();

    final color = phaseColor(phase.kind);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Название тренировки
        Text(
          w.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: subColor,
          ),
        ),
        const SizedBox(height: 16),
        // Кольцо текущей фазы
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: RepaintBoundary(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: _PhaseRingPainter(
                      progress: wp.phaseProgress,
                      color: color,
                      isDark: isDark,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(phaseIcon(phase.kind), size: 34, color: color),
                      const SizedBox(height: 6),
                      Text(
                        fmtTime(wp.phaseRemaining),
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'фаза ${wp.phaseIndex + 1} из ${w.phases.length}',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Название и подсказка фазы
        Text(
          phase.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          phase.hint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: subColor, height: 1.4),
        ),
        if (next != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(phaseIcon(next.kind), size: 14, color: subColor),
              const SizedBox(width: 5),
              Text(
                'Далее: ${next.title.toLowerCase()} ${fmtTime(next.seconds)}',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        // Полоса всей тренировки по фазам
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Row(
            children: [
              for (int i = 0; i < w.phases.length; i++)
                Expanded(
                  flex: w.phases[i].seconds,
                  child: Container(
                    height: 10,
                    color: i < wp.phaseIndex
                        ? phaseColor(w.phases[i].kind)
                        : i == wp.phaseIndex
                            ? phaseColor(w.phases[i].kind)
                            : phaseColor(w.phases[i].kind)
                                .withValues(alpha: isDark ? 0.2 : 0.25),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'До конца тренировки: ${fmtTime(wp.totalRemaining)}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: subColor),
        ),
        const SizedBox(height: 18),
        // Живые шаги и калории
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                icon: Icons.directions_walk,
                value: '${wp.workoutSteps}',
                label: 'шагов за тренировку',
                color: const Color(0xFF00C853),
                textColor: textColor,
                subColor: subColor,
              ),
              Container(width: 1, height: 36, color: borderColor),
              _StatChip(
                icon: Icons.local_fire_department,
                value: '${wp.workoutCalories}',
                label: 'ккал',
                color: const Color(0xFFFF1744),
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Завершить досрочно
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF1744),
              side: const BorderSide(color: Color(0xFFFF1744)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.stop),
            label: const Text(
              'Завершить досрочно',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            onPressed: () async {
              final wp = context.read<WorkoutProvider>();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Завершить тренировку?'),
                  content: const Text(
                      'Пройденное время и шаги засчитаются в статистику.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Продолжить'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Завершить'),
                    ),
                  ],
                ),
              );
              if (confirm == true) wp.finishEarly();
            },
          ),
        ),
      ],
    );
  }
}

// Итоги тренировки
class _FinishedView extends StatelessWidget {
  final bool isDark;
  const _FinishedView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    final w = wp.workout;
    const green = Color(0xFF00C853);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);

    final completedFully = w != null && wp.elapsedTotal >= w.totalSeconds;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.emoji_events, size: 72, color: green),
        const SizedBox(height: 12),
        Text(
          completedFully ? 'Тренировка завершена!' : 'Тренировка остановлена',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          completedFully
              ? 'Прошёл все фазы — так держать, чемпион!'
              : 'Главное - начать. Засчитано в статистику.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: subColor),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                icon: Icons.timer,
                value: fmtTime(wp.elapsedTotal),
                label: 'время',
                color: const Color(0xFF0091EA),
                textColor: textColor,
                subColor: subColor,
              ),
              Container(width: 1, height: 36, color: borderColor),
              _StatChip(
                icon: Icons.directions_walk,
                value: '${wp.workoutSteps}',
                label: 'шагов',
                color: green,
                textColor: textColor,
                subColor: subColor,
              ),
              Container(width: 1, height: 36, color: borderColor),
              _StatChip(
                icon: Icons.local_fire_department,
                value: '${wp.workoutCalories}',
                label: 'ккал',
                color: const Color(0xFFFF1744),
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.replay),
            label: const Text(
              'Ещё одна тренировка',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            onPressed: () => context.read<WorkoutProvider>().backToList(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              context.read<WorkoutProvider>().backToList();
              Navigator.of(context).pop();
            },
            child: Text(
              'Готово',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: subColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Рисовальщик кольца фазы (упрощённая версия кольца с главного экрана)
class _PhaseRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _PhaseRingPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2A38) : const Color(0xFFD1D9E6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      // Свечение под дугой
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final ringRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * progress, false, glowPaint);

      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_PhaseRingPainter old) =>
      old.progress != progress || old.color != color || old.isDark != isDark;
}
