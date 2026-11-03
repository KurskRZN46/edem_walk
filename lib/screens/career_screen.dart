import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/career.dart';
import '../data/league.dart';
import '../data/quests.dart';
import '../providers/career_provider.dart';
import '../providers/avatar_provider.dart';
import '../providers/normative_provider.dart';
import '../providers/step_provider.dart';

// Экран карьеры: ранг игрока, статистика матчей, достижения.
class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key});

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  @override
  void initState() {
    super.initState();
    // Обновляем статистику матчей при каждом открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CareerProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final career = context.watch<CareerProvider>();
    final stepProvider = context.watch<StepProvider>();
    final avatar = context.watch<AvatarProvider>().selected;
    final norm = context.watch<NormativeProvider>().selected;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stats = stepProvider.statsSummary;
    final totalKm = stepProvider.totalKmAllTime;
    final streak = stepProvider.streakDays;

    final rank = rankForKm(totalKm);
    final next = nextRankForKm(totalKm);
    final progress = rankProgress(totalKm);
    final items = career.achievements(
      totalSteps: stats['total'] ?? 0,
      bestDaySteps: stats['best'] ?? 0,
      streakDays: streak,
      totalKm: totalKm,
    );
    final unlocked = items.where((e) => e.unlocked).length;

    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);
    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _CareerHeader(isDark: isDark, theme: theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ЗАДАНИЯ НА СЕГОДНЯ
                  Text(
                    'Задания на сегодня',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _QuestTile(
                    quest: dailyQuests[0],
                    progress: (stepProvider.steps / 6000).clamp(0.0, 1.0),
                    valueText: '${stepProvider.steps} / 6000',
                    done: stepProvider.steps >= 6000,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _QuestTile(
                    quest: dailyQuests[1],
                    progress: norm.targetKm > 0
                        ? (stepProvider.km / norm.targetKm).clamp(0.0, 1.0)
                        : 0.0,
                    valueText:
                        '${stepProvider.km.toStringAsFixed(2)} / ${norm.targetKm.toStringAsFixed(1)} км',
                    done: stepProvider.km >= norm.targetKm,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _QuestTile(
                    quest: dailyQuests[2],
                    progress: career.playedToday ? 1.0 : 0.0,
                    valueText: career.playedToday ? 'сыгран' : 'не сыгран',
                    done: career.playedToday,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 18),
                  // РАНГ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF102218), const Color(0xFF151B23)]
                            : [const Color(0xFFD7FFE6), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: green.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        // Аватар профиля с иконкой ранга поверх
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: green, width: 2.5),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  avatar.asset,
                                  cacheWidth: 252, // Декодируем под реальный размер (84 * 3)
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    _iconFor(rank.iconKey),
                                    size: 44,
                                    color: green,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: green,
                                child: Icon(_iconFor(rank.iconKey),
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          rank.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rank.motto,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? const Color(0xFF1E2730)
                                : const Color(0xFFE8ECF1),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(green),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          next == null
                              ? 'Максимальный ранг! ${totalKm.toStringAsFixed(1)} км'
                              : '${totalKm.toStringAsFixed(1)} / ${next.minKm.toStringAsFixed(0)} км до ранга «${next.name}»',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // СТАТИСТИКА МАТЧЕЙ
                  Row(
                    children: [
                      _MiniStat(
                        value: '${career.matches}',
                        label: 'матчей',
                        isDark: isDark,
                        accent: green,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        value: '${career.wins}',
                        label: 'побед',
                        isDark: isDark,
                        accent: red,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        value: '${career.goals}',
                        label: 'голов',
                        isDark: isDark,
                        accent: green,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        value: '$streak',
                        label: 'дней серия',
                        isDark: isDark,
                        accent: red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // ЛИГА НЕДЕЛИ
                  Builder(builder: (context) {
                    // Шаги пользователя с понедельника
                    final monday = mondayOf(DateTime.now());
                    final mondayKey =
                        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
                    var weekSteps = 0;
                    for (final e in stepProvider.getHistory(7)) {
                      if (e.key.compareTo(mondayKey) >= 0) weekSteps += e.value;
                    }
                    final rows = career.leagueStandings(weekSteps);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Лига недели',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                career.leagueName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Топ-2 выходят в дивизион выше, последние двое вылетают',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < rows.length; i++) ...[
                                _LeagueRow(
                                  place: i + 1,
                                  name: rows[i].name,
                                  steps: rows[i].steps,
                                  isUser: rows[i].isUser,
                                  isDark: isDark,
                                ),
                                if (i < rows.length - 1)
                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? const Color(0xFF1E2730)
                                        : const Color(0xFFE8ECF1),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 18),
                  // ДОСТИЖЕНИЯ
                  Text(
                    'Достижения  $unlocked/${items.length}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final a = item.achievement;
                      final on = item.unlocked;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: on
                              ? green.withValues(alpha: isDark ? 0.15 : 0.08)
                              : cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: on
                                ? green.withValues(alpha: 0.6)
                                : borderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  on ? _iconFor(a.iconKey) : Icons.lock_outline,
                                  size: 22,
                                  color: on ? green : subColor,
                                ),
                                const Spacer(),
                                if (on)
                                  const Icon(Icons.check_circle,
                                      size: 16, color: green),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              a.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: on ? textColor : subColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: subColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // ПОДЕЛИТЬСЯ РЕЗУЛЬТАТОМ
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: green,
                        side: const BorderSide(color: green),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text(
                        'Поделиться результатом',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: '⚽ Моя карьера в Edem Walk:\n'
                                'Ранг: ${rank.name}\n'
                                'Пройдено: ${totalKm.toStringAsFixed(1)} км\n'
                                'Матчей: ${career.matches}, побед: ${career.wins}, голов: ${career.goals}\n'
                                'Серия: $streak дн.\n'
                                'Достижения: $unlocked/${items.length}\n'
                                'Тренируйся как футболист!',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Маппинг строковых ключей иконок из data/career.dart
  IconData _iconFor(String key) {
    switch (key) {
      case 'boot':
        return Icons.directions_walk;
      case 'shirt':
        return Icons.checkroom;
      case 'ball':
        return Icons.sports_soccer;
      case 'band':
        return Icons.military_tech;
      case 'crown':
        return Icons.workspace_premium;
      case 'whistle':
        return Icons.sports;
      case 'cup':
        return Icons.emoji_events;
      case 'target':
        return Icons.gps_fixed;
      case 'run':
        return Icons.directions_run;
      case 'fire':
        return Icons.local_fire_department;
      case 'shield':
        return Icons.shield;
      case 'road':
        return Icons.add_road;
      case 'fitness':
        return Icons.fitness_center;
      case 'engine':
        return Icons.speed;
      default:
        return Icons.star;
    }
  }
}

// Хедер экрана карьеры
class _CareerHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _CareerHeader({required this.isDark, required this.theme});

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
            'Карьера',
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

// Строка таблицы лиги
class _LeagueRow extends StatelessWidget {
  final int place;
  final String name;
  final int steps;
  final bool isUser;
  final bool isDark;

  const _LeagueRow({
    required this.place,
    required this.name,
    required this.steps,
    required this.isUser,
    required this.isDark,
  });

  String _fmt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    // Зоны: 1-2 повышение (зелёная), 5-6 вылет (красная)
    final zoneColor = place <= 2 ? green : (place >= 5 ? red : subColor);

    return Container(
      color: isUser ? green.withValues(alpha: isDark ? 0.12 : 0.07) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$place',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: zoneColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isUser ? FontWeight.w900 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Text(
            _fmt(steps),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isUser ? green : subColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Карточка ежедневного задания с прогрессом
class _QuestTile extends StatelessWidget {
  final DailyQuest quest;
  final double progress; // 0.0 - 1.0
  final String valueText;
  final bool done;
  final bool isDark;

  const _QuestTile({
    required this.quest,
    required this.progress,
    required this.valueText,
    required this.done,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: done
            ? green.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? const Color(0xFF151B23) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? green.withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : _questIcon(quest.iconKey),
            size: 24,
            color: done ? green : subColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                Text(
                  '${quest.description} • $valueText',
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? const Color(0xFF1E2730)
                        : const Color(0xFFE8ECF1),
                    valueColor: const AlwaysStoppedAnimation<Color>(green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _questIcon(String key) {
    switch (key) {
      case 'run':
        return Icons.directions_run;
      case 'ball':
        return Icons.sports_soccer;
      case 'whistle':
        return Icons.sports;
      default:
        return Icons.flag;
    }
  }
}

// Маленькая карточка статистики
class _MiniStat extends StatelessWidget {  final String value;
  final String label;
  final bool isDark;
  final Color accent;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151B23) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
