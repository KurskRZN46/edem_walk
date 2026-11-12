import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../services/step_service.dart';
import '../widgets/notification_settings_card.dart';

// StatefulWidget, потому что есть TextEditingController для ручного ввода цели
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _goalController; // Контроллер текстового поля для кастомной цели

  @override
  void initState() {
    super.initState();
    final stepProvider = context.read<StepProvider>(); // Прочитать один раз без подписки (в initState нельзя использовать watch)
    _goalController = TextEditingController(text: stepProvider.customGoal.toString()); // Создаём контроллер с текущим значением кастомной цели
  }

  @override
  void dispose() { // Освобождаем контроллер против утечки памяти
    _goalController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);

    final cardColor = isDark ? const Color(0xFF151B23) : const Color(0xFFEDF1F6);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(isDark: isDark, theme: theme),
            Expanded(
              child: ListView( // Так как может не влезть на маленький экран
                padding: const EdgeInsets.all(20),
                children: [
                  // ДНЕВНАЯ ЦЕЛЬ
                  _SectionCard(
                    color: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок с иконкой флажка
                        Row(
                          children: [
                            const Icon(Icons.flag, color: green, size: 22),
                            const SizedBox(width: 10),
                            Text('Дневная цель',
                                style: theme.textTheme.titleMedium ?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Режим "Автопрогрессия"
                        _GoalModeTile(
                          selected: stepProvider.useSystemGoals,
                          onTap: () =>
                              stepProvider.setUseSystemGoals(true),
                          icon: Icons.trending_up,
                          title: 'Автопрогрессия',
                          subtitle: 'Цель растёт автоматически',
                          isDark: isDark,
                          accent: green,
                        ),
                        // Если выбран режим автопрогрессии, показываем список целей
                        if (stepProvider.useSystemGoals) ...[
                          const SizedBox(height: 12),
                          Wrap( // Как Row, но переносит элементы на новую строку, если не влезают
                            spacing: 8, // Отступ по горизонтали
                            runSpacing: 8, // Отступ по вертикали
                            children: List.generate(
                                StepService.systemGoals.length, (i) {
                              final reached = i < stepProvider.currentGoalIndex; // Эта цель уже пройдена
                              final current = i == stepProvider.currentGoalIndex; // Эта цель сейчас активна
                              final g = StepService.systemGoals[i];
                              final label = g >= 1000 ? '${g ~/ 1000}K' : g.toString(); // "1000" -> "1K", "500" -> "500"
                              // Чипс нажимаемый: тап переключает текущую цель на эту
                              return GestureDetector(
                                onTap: () {
                                  stepProvider.setGoalIndex(i);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Цель: $g шагов'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: current ? green : reached ? green.withValues(alpha: 0.15) : (isDark ? const Color(0xFF0B0F14) : const Color(0xFFE0E5EC)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: current // Рамка только для неактивных
                                      ? null
                                      : Border.all(
                                          color: isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD),
                                          width: 1),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    // Активная - Пройденная - Будущая цель
                                    color: current ? Colors.white : reached ? green : (isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577)),
                                  ),
                                ),
                              ),
                            );
                            }),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Режим своей цели
                        _GoalModeTile(
                          selected: !stepProvider.useSystemGoals,
                          onTap: () => stepProvider.setUseSystemGoals(false),
                          icon: Icons.tune,
                          title: 'Своя цель',
                          subtitle: 'Установите вручную',
                          isDark: isDark,
                          accent: green,
                        ),
                        // Если выбран режим своей цели показываем поле ввода и кнопку
                        if (!stepProvider.useSystemGoals) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox( // Поле ввода
                                width: 140,
                                child: TextField(
                                  controller: _goalController,
                                  keyboardType: TextInputType.number, // Только цифры на клавиатуре
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    suffixText: 'шагов',
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0B0F14) : const Color(0xFFE0E5EC),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded( // Кнопка "Применить"
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: green),
                                  onPressed: () {
                                    final value = int.tryParse(_goalController.text); // Парсим число из поля
                                    if (value != null && value >= 1) {
                                      stepProvider.updateGoal(value);
                                      ScaffoldMessenger.of(context).showSnackBar( // Показываем уведомление об успехе
                                        const SnackBar(
                                          content: Text('Цель обновлена'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar( // Ошибка: не число или меньше 1
                                        const SnackBar(
                                          content:
                                              Text('Введите число от 1'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Применить'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Плашка "Текущая цель: X шагов"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: red, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Текущая цель: ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? const Color(0xFF8B95A7)
                                        : const Color(0xFF5A6577),
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${stepProvider.dailyGoal}',
                                style: const TextStyle(
                                    color: Color(0xFFFF1744),
                                    fontWeight: FontWeight.w900),
                              ),
                              Text(
                                ' шагов',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? const Color(0xFF8B95A7)
                                        : const Color(0xFF5A6577),
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // УВЕДОМЛЕНИЯ (v12)
                  const NotificationSettingsCard(),
                  const SizedBox(height: 16),
                  // ТЕМА
                  _SectionCard(
                    color: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.brightness_4,
                                color: green, size: 22),
                            const SizedBox(width: 10),
                            Text('Тема приложения',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ThemeOption(
                          label: 'Системная',
                          icon: Icons.smartphone,
                          selected:
                              stepProvider.themeMode == ThemeMode.system,
                          onTap: () =>
                              stepProvider.setThemeMode(ThemeMode.system),
                          isDark: isDark,
                          accent: green,
                        ),
                        const SizedBox(height: 8),
                        _ThemeOption(
                          label: 'Светлая',
                          icon: Icons.light_mode,
                          selected:
                              stepProvider.themeMode == ThemeMode.light,
                          onTap: () =>
                              stepProvider.setThemeMode(ThemeMode.light),
                          isDark: isDark,
                          accent: green,
                        ),
                        const SizedBox(height: 8),
                        _ThemeOption(
                          label: 'Тёмная',
                          icon: Icons.dark_mode,
                          selected:
                              stepProvider.themeMode == ThemeMode.dark,
                          onTap: () =>
                              stepProvider.setThemeMode(ThemeMode.dark),
                          isDark: isDark,
                          accent: green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // СТАТИСТИКА (СБРОС)
                  _SectionCard(
                    color: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bar_chart,
                                color: green, size: 22),
                            const SizedBox(width: 10),
                            Text('Статистика',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.delete_outline,
                                color: red),
                            label: const Text('Сбросить статистику',
                                style: TextStyle(color: red)),
                            style: FilledButton.styleFrom(
                              backgroundColor: red.withValues(alpha: 0.08),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () { // Сброс статистики через диалог
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Сброс статистики'),
                                  content: const Text(
                                    'Все сохранённые шаги, серия и прогресс целей '
                                    'будут удалены. Это действие нельзя отменить.',
                                  ),
                                  actions: [
                                    TextButton( // Отмена - просто закрыть диалог
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton( // Сброс - вызвать resetHistory
                                      onPressed: () async {
                                        await stepProvider.resetHistory();
                                        if (!context.mounted) return; // Виджет жив
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('История очищена'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: const Text('Сбросить'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // ВЕРСИЯ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Версия',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577))),
                      Text('1.0.0+1',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Карточка секции. Простой контейнер с фоном и скруглением для группировки нескольких виджетов
class _SectionCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const _SectionCard({required this.color, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

// Хедер настроек
class _SettingsHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _SettingsHeader({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF151B23) : const Color(0xFFE8ECF1);
    const red = Color(0xFFFF1744);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
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
            'Настройки',
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

// Плитка режима цели
class _GoalModeTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color accent;

  const _GoalModeTile({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : (isDark ? const Color(0xFF0B0F14) : const Color(0xFFE0E5EC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : (isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, // Иконка слева
                color: selected ? accent : (isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577)),
                size: 22),
            const SizedBox(width: 12),
            Expanded( // Текст в центре (занимает всё свободное место)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: selected ? accent : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577),
                      )),
                ],
              ),
            ),
            Icon( // Радио-кнопка справа: круглая с точкой или пустая
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? const Color(0xFF00C853) : (isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577)),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// Плитка выбора темы
class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color accent;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : (isDark
                  ? const Color(0xFF0B0F14)
                  : const Color(0xFFE0E5EC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent
                : (isDark
                    ? const Color(0xFF1E2730)
                    : const Color(0xFFD0D5DD)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? accent
                    : (isDark
                        ? const Color(0xFF8B95A7)
                        : const Color(0xFF5A6577)),
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: selected
                        ? accent
                        : (isDark
                            ? Colors.white
                            : const Color(0xFF1A1A2E)),
                  )),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? accent
                  : (isDark
                      ? const Color(0xFF8B95A7)
                      : const Color(0xFF5A6577)),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}