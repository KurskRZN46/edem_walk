import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/step_provider.dart';

// StatelessWidget, потому что всё состояние в провайдере
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final history = stepProvider.getHistory(7); // Cписок из 7 записей от старой к новой
    final hasData = history.any((e) => e.value > 0); // Есть ли хоть один день с шагами > 0
    final maxSteps = history.fold<int>(0, (a, e) => a > e.value ? a : e.value); // Максимум из всех 7 дней (нужен для верхней границы графика)

    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    String dayLabel(String key) {
      final parts = key.split('-');
      final dt = DateTime(
        int.parse(parts[0]), // год
        int.parse(parts[1]), // месяц
        int.parse(parts[2]), // день
      );
      return dayNames[dt.weekday - 1];
    }

    return Scaffold( // Каркас экрана
      backgroundColor: isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB), // Фон: тёмный в тёмной теме, светлый в светлой
      body: SafeArea(
        child: Column(
          children: [
            _HistoryHeader(isDark: isDark, theme: theme), // Хедер со стрелкой назад
            Expanded( // Забирает всё место под хедером
              child: hasData // Если есть данные, то график и список, иначе ничего
                  ? _buildContent(history, maxSteps, dayLabel, cs, theme, isDark, stepProvider)
                  : _buildEmpty(cs, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Пустое состояние
  Widget _buildEmpty(ColorScheme cs, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, // Иконка истории
              size: 72,
              color: isDark ? const Color(0xFF3A4553) : const Color(0xFFB0B8C4)),
          const SizedBox(height: 20),
          Text('Нет данных за неделю',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Padding( // Подсказка. Padding по бокам, чтобы текст не растягивался на всю ширину
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Начните ходить — и здесь появится статистика',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577)),
            ),
          ),
        ],
      ),
    );
  }

  // Основной контент (дашборд + график + список)
  Widget _buildContent(
    List<MapEntry<String, int>> history,
    int maxSteps,
    String Function(String) dayLabel,
    ColorScheme cs,
    ThemeData theme,
    bool isDark,
    StepProvider stepProvider,
  ) {
    final chartMax = (maxSteps / 1000).ceil() * 1000; // Вверхняя граница оси Y графика
    final chartMaxSafe = chartMax < 1000 ? 1000 : chartMax; // Защита от нуля. Если всё по нулям, ставим минимум 1000
    const green = Color(0xFF00C853); // Акцент
    const red = Color(0xFFFF1744);

    // Дашборд: суммарная статистика за всё время
    final stats = stepProvider.statsSummary;
    final totalSteps = stats['total'] ?? 0;
    final bestDay = stats['best'] ?? 0;
    final totalKm = stepProvider.totalKmAllTime;
    final avgSteps = stepProvider.averageSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Всё выравнивается по левому краю
        children: [
          // ДАШБОРД: 4 карточки с итогами за всё время
          Text('Дашборд', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatCard(
                icon: Icons.directions_walk,
                value: _formatCompact(totalSteps),
                label: 'всего шагов',
                isDark: isDark,
                accent: green,
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.straighten,
                value: totalKm.toStringAsFixed(1),
                label: 'всего км',
                isDark: isDark,
                accent: red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatCard(
                icon: Icons.show_chart,
                value: _formatCompact(avgSteps),
                label: 'в среднем за день',
                isDark: isDark,
                accent: red,
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.emoji_events,
                value: _formatCompact(bestDay),
                label: 'лучший день',
                isDark: isDark,
                accent: green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('График активности', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)), // Заголовок графика
          const SizedBox(height: 8),
          Expanded( // График
            flex: 4, // Занимает 40% свободного места
            child: BarChart( 
              BarChartData( // Описание графика, fl_chart сам рисует
                alignment: BarChartAlignment.spaceAround, // Cтержни равномерно распределены
                maxY: chartMaxSafe.toDouble(), // Верхняя граница оси Y
                minY: 0, // Нижняя граница оси Y
                gridData: FlGridData( // Сетка с горизонтальными линиями на фоне
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: chartMaxSafe / 2, // Через сколько рисовать линию (2 линии, одна посередине, одна вверху)
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF1E2730) : const Color(0xFFE0E5EC),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData( // Подписи осей
                  show: true,
                  bottomTitles: AxisTitles( // Нижняя ось - названия дней недели
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) { // Функция, которая решает, что нарисовать под каждым стержнем
                        final i = value.toInt();
                        if (i < 0 || i >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(dayLabel(history[i].key),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577))),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles( // // Левая ось - числа
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: chartMaxSafe / 2,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink(); // 0 и так на оси
                        return Text(
                          value >= 1000 ? '${(value / 1000).round()}к' : value.toInt().toString(),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577)),
                        );
                      },
                      reservedSize: 30, // Место под подписи
                    ),
                  ),
                  // Правую и верхнюю оси не рисуем
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false), // Убираем рамку вокруг графика
                // Стержни
                barGroups: List.generate(history.length, (i) { // Cписок групп. У нас 1 стержень в группе
                  final steps = history[i].value;
                  final isToday = i == history.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: steps.toDouble(), // Высота стержня
                        color: isToday ? green : green.withValues(alpha: 0.4), // Сегодняшний день выделяем ярче
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Заголовок списка
          Text('Детали по дням', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded( // Список
            flex: 6,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 5), // Что рисовать между элементами
              itemBuilder: (context, idx) { // Что рисовать для каждого элемента
                final i = history.length - 1 - idx; // i считаем наоборот: список показывает свежие сверху. history[6] = сегодня -> первый в списке
                final entry = history[i];
                final isToday = i == history.length - 1;
                final label = dayLabel(entry.key);
                final parts = entry.key.split('-'); // Парсим дату из ключа, чтобы показать "10 окт"
                final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                final dateStr = '${dt.day} ${monthNames[dt.month - 1]}';
                return Container( // Контейнер одной строки списка
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF151B23) : const Color(0xFFEDF1F6),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday // Рамка только для сегодняшнего дня
                        ? Border.all(color: green.withValues(alpha: 0.5), width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row( // Левая часть: день недели + дата + метка
                        children: [
                          SizedBox(
                            width: 32, // Фиксированная ширина, чтобы дни не плясали
                            child: Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: green,
                                    fontSize: 14)),
                          ),
                          Text(dateStr,
                              style: TextStyle(
                                  color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577),
                                  fontSize: 13)),
                          if (isToday) ...[ // Метка "сегодня"
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('сегодня',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: red)),
                            ),
                          ],
                        ],
                      ),
                      Text('${entry.value}', // Правая часть: количество шагов
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const monthNames = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];
}

// Форматирует большие числа компактно: 15300 -> "15.3K"
String _formatCompact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toString();
}

// Карточка одной метрики дашборда
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;
  final Color accent;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151B23) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}

// Хедер истории
class _HistoryHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _HistoryHeader({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF151B23) : const Color(0xFFE8ECF1);
    const red = Color(0xFFFF1744);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: red.withValues(alpha: 0.6), width: 2)), // Тонкая красная полоса снизу
        boxShadow: [ // Тень
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
          IconButton( // Кнопка "назад"
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
            onPressed: () => Navigator.of(context).pop(), // Вернуться к предыдущему экрану (HomeScreen)
          ),
          Text( // Заголовок
            'История за 7 дней',
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