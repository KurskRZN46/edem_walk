import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../providers/career_provider.dart';
import '../providers/step_provider.dart';
import '../services/step_service.dart' show PermissionState;

// Экран режима «Матч»: таймер, счёт, лента комментатора.
// Голы начисляются за шаги, пройденные после старта матча.
class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final match = context.watch<MatchProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _MatchHeader(
              isDark: isDark,
              theme: theme,
              showBack: match.phase != MatchPhase.running,
            ),
            Expanded(
              child: switch (match.phase) {
                MatchPhase.idle => _IdleView(isDark: isDark),
                MatchPhase.running => _RunningView(isDark: isDark),
                MatchPhase.finished => _FinishedView(isDark: isDark),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Хедер с красной полосой (в стиле остальных экранов)
class _MatchHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final bool showBack; // во время матча прячем "назад", чтобы не потерять контекст

  const _MatchHeader({
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
          const Icon(Icons.sports_soccer, color: red, size: 20),
          const SizedBox(width: 8),
          Text(
            'Матч',
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

// Выбор длительности и старт матча
class _IdleView extends StatelessWidget {
  final bool isDark;
  const _IdleView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final match = context.watch<MatchProvider>();
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              const Icon(Icons.stadium, size: 56, color: green),
              const SizedBox(height: 12),
              Text(
                'Сыграй матч шагами',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Каждые ${MatchProvider.stepsPerGoal} шагов — один гол. '
                'Ходи, бегай, забивай — а комментатор расскажет, что происходит на поле.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subColor, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Длительность матча',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final d in MatchProvider.availableDurations)
              GestureDetector(
                onTap: () => match.setDuration(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: match.durationMin == d ? green : cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: match.durationMin == d ? green : borderColor,
                    ),
                  ),
                  child: Text(
                    '$d мин',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: match.durationMin == d ? Colors.white : textColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Внутри матча время идёт как в футболе: минуты 1–90',
          style: TextStyle(fontSize: 12, color: subColor),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'Начать матч',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            onPressed: () async {
              final stepProvider = context.read<StepProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final started = await match.startMatch(match.durationMin);
              if (!started) {
                final permanently = stepProvider.permissionState ==
                    PermissionState.permanentlyDenied;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      permanently
                          ? 'Нет доступа к датчику шагов. Разрешите его в настройках телефона'
                          : 'Для матча нужен запущенный шагомер — разрешите доступ к активности',
                    ),
                    action: SnackBarAction(
                      label: 'Настройки',
                      onPressed: () => stepProvider.openSystemSettings(),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// Идущий матч: табло, прогресс до гола, лента событий
class _RunningView extends StatelessWidget {
  final bool isDark;
  const _RunningView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final match = context.watch<MatchProvider>();
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Минута матча
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${match.footballMinute}'  •  ${match.clock}",
                    style: const TextStyle(
                      color: red,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // СЧЁТ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.directions_run, color: green, size: 30),
                        const SizedBox(height: 4),
                        Text('Ты',
                            style: TextStyle(fontSize: 13, color: subColor)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      // Счёт "подпрыгивает" при изменении - ключ ValueKey пересоздаёт виджет
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.elasticOut,
                          ),
                          child: child,
                        ),
                        child: Text(
                          '${match.myGoals} : ${match.oppGoals}',
                          key: ValueKey('${match.myGoals}:${match.oppGoals}'),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Icon(Icons.groups, color: red, size: 30),
                        const SizedBox(height: 4),
                        Text('Соперник',
                            style: TextStyle(fontSize: 13, color: subColor)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Прогресс времени матча
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: match.timeProgress,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? const Color(0xFF1E2730)
                        : const Color(0xFFE8ECF1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                  ),
                ),
                const SizedBox(height: 12),
                // Прогресс до следующего гола
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'До гола: ${match.stepsToNextGoal} шагов',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: subColor),
                    ),
                    Text(
                      '${match.matchSteps} шагов в матче',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: match.nextGoalProgress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? const Color(0xFF1E2730)
                        : const Color(0xFFE8ECF1),
                    valueColor: const AlwaysStoppedAnimation<Color>(green),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Лента комментатора
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Комментатор',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: match.events.length,
            itemBuilder: (context, i) {
              final e = match.events[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: e.highlight
                      ? green.withValues(alpha: isDark ? 0.15 : 0.1)
                      : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: e.highlight
                        ? green.withValues(alpha: 0.5)
                        : borderColor,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        "${e.minute}'",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: e.highlight ? green : subColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              e.highlight ? FontWeight.w700 : FontWeight.w400,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Завершить досрочно
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton.icon(
            onPressed: () => _confirmFinish(context),
            icon: const Icon(Icons.flag, color: Colors.blueGrey),
            label: const Text(
              'Завершить досрочно',
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmFinish(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завершить матч?'),
        content: const Text('Результат будет зафиксирован как есть.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Продолжить'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<MatchProvider>().finishEarly();
            },
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }
}

// Результат матча
class _FinishedView extends StatelessWidget {
  final bool isDark;
  const _FinishedView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final match = context.watch<MatchProvider>();
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    final (emoji, title, color) = switch (match.result) {
      'win' => ('🏆', 'Победа!', green),
      'draw' => ('🤝', 'Ничья', Colors.blueGrey),
      _ => ('💪', 'Поражение', red),
    };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${match.myGoals} : ${match.oppGoals}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Шагов в матче: ${match.matchSteps}  •  '
                'Км: ${(match.matchSteps * 0.00075).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, color: subColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Финальная лента
        for (final e in match.events)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    "${e.minute}'",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: subColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.text,
                    style: TextStyle(fontSize: 13, color: textColor, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.replay),
          label: const Text(
            'Новый матч',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          onPressed: () {
            match.resetToIdle();
            // Обновляем карьерную статистику после матча
            context.read<CareerProvider>().refresh();
          },
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            context.read<CareerProvider>().refresh();
            Navigator.of(context).pop();
          },
          child: const Text('На главную'),
        ),
      ],
    );
  }
}
