import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../providers/normative_provider.dart';
import '../services/step_service.dart' show PermissionState;
import 'settings_screen.dart';
import 'history_screen.dart';
import 'normatives_screen.dart';
import 'footballers_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>(); // Подписываемся на StepProvider. Когда сервис вызывает notifyListeners(), HomeScreen перерисуется
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = stepProvider.steps;
    final goal = stepProvider.dailyGoal;
    final progress = stepProvider.goalProgress;
    final isRunning = stepProvider.isRunning;
    final km = stepProvider.km;
    final calories = stepProvider.calories;
    final percent = stepProvider.percent;
    final streak = stepProvider.streakDays;
    final showGoalReached = stepProvider.showGoalReached;

    // Режим «Нормативы футболиста»: выбранная позиция и её средняя норма в км
    final norm = context.watch<NormativeProvider>().selected;
    final normTarget = norm.targetKm;
    final normProgress = normTarget > 0 ? (km / normTarget).clamp(0.0, 1.0) : 0.0;

    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);

    return Scaffold( // Каркас экрана
      backgroundColor:
          isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea( // Обрезает верх/низ, чтобы контент не залазил
        child: Column( // Располагает детей вертикально
          children: [
            _Header(isDark: isDark, streak: streak, theme: theme), // Заголовок слева, серия (огонёк) справа
            Expanded( // Забирает всё оставшееся место под хедером
              child: Padding( // Горизонтальные отступы по бокам
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12), // Небольшой отступ от хедера до круга
                    // КРУГ С ШАГАМИ
                    Align( // Выравнивает по центру по горизонтали
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: Stack( // Накладывает виджеты друг на друга
                          alignment: Alignment.center,
                          children: [
                            CustomPaint( // Кольцо прогресса
                              size: const Size(300, 300),
                              painter: _ProgressRingPainter(progress, isDark),
                            ),
                            Column( // Cодержимое круга
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // Не растягивается
                              children: [
                                Container( // Иконка приложения с обводкой
                                  padding: const EdgeInsets.all(3), // Отступ между обводкой и иконкой
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, // Круглая обводка
                                    border: Border.all(color: green, width: 2.5),
                                  ),
                                  child: ClipOval( // Обрезает картинку по кругу
                                    child: Image.asset(
                                      'assets/icon/app_icon.png', // Собственная иконка приложения (без чужих изображений)
                                      width: 104,
                                      height: 104,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _placeholderAvatar(green),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text( // Число шагов
                                  '$steps',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text( // Процент от цели
                                  '$percent%',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00C853),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ЦЕЛЬ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Цель: ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577),
                          ),
                        ),
                        Text(
                          '$goal',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF1744),
                          ),
                        ),
                        Text(
                          ' шагов',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577),
                          ),
                        ),
                      ],
                    ),
                    // ПЛАШКА "ЦЕЛЬ ДОСТИГНУТА"
                    const SizedBox(height: 8),
                    if (showGoalReached)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, color: Colors.white, size: 16), // Кубок
                            SizedBox(width: 6),
                            Text(
                              'Цель достигнута!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // МЕТРИКИ (КМ / КАЛ)
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MetricItem( // Лево: километры
                          icon: Icons.straighten, // Линейка
                          value: '${km.toStringAsFixed(2)} км',
                          isDark: isDark,
                        ),
                        Container( // Вертикальный разделитель между метриками
                          width: 1,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 28),
                          color: isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD),
                        ),
                        _MetricItem( // Право: калории
                          icon: Icons.local_fire_department, // Огонёк
                          value: '$calories кал',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    // БАННЕР «НОРМАТИВ ФУТБОЛИСТА» (тап - открыть экран нормативов)
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NormativesScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151B23) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_soccer, size: 20, color: Color(0xFFFF1744)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Норматив ${norm.nameGenitive}: ${km.toStringAsFixed(2)} / ${normTarget.toStringAsFixed(1)} км',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: normProgress,
                                      minHeight: 6,
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E2730)
                                          : const Color(0xFFE8ECF1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // КНОПКА СТАРТ/СТОП
                    const SizedBox(height: 18),
                    GestureDetector( // Ловит тапы на любом своём ребёнке
                      onTap: () async {
                        if (isRunning) {
                          stepProvider.stop();
                          return;
                        }
                        // Запускаем и ждём результат: если не запустилось
                        // (нет разрешения / нативная часть не ответила) -
                        // показываем понятную подсказку, а не молчим
                        final started = await stepProvider.start();
                        if (!context.mounted) return;
                        if (!started && !stepProvider.isRunning) {
                          final permanently = stepProvider.permissionState ==
                              PermissionState.permanentlyDenied;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                permanently
                                    ? 'Нет доступа к датчику шагов. Разрешите его в настройках телефона'
                                    : 'Для подсчёта шагов нужно разрешение на доступ к активности',
                              ),
                              action: SnackBarAction(
                                label: 'Открыть настройки',
                                onPressed: () => stepProvider.openSystemSettings(),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isRunning
                              ? (isDark
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFF333333))
                              : red,
                          shape: BoxShape.circle,
                          border: isRunning // Обводка только когда работает
                              ? Border.all(color: red, width: 2.5)
                              : null,
                        ),
                        child: Icon( // Иконка: stop (квадрат) если работает, play (треугольник) если нет
                          isRunning ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // НИЖНИЕ КНОПКИ (НАВИГАЦИЯ)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Равные отступы между детьми и от краёв
                      children: [
                        _NavButton(
                          icon: Icons.history,
                          label: 'История',
                          isDark: isDark,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          ),
                        ),
                        _NavButton(
                          icon: Icons.sports_soccer,
                          label: 'Нормативы',
                          isDark: isDark,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NormativesScreen()),
                          ),
                        ),
                        _NavButton(
                          icon: Icons.groups,
                          label: 'Футболисты',
                          isDark: isDark,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FootballersScreen()),
                          ),
                        ),
                        _NavButton(
                          icon: Icons.settings,
                          label: 'Настройки',
                          isDark: isDark,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(), // Забирает всё оставшееся место
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Рисует заглушку аватара
  Widget _placeholderAvatar(Color color) {
    return Container(
      width: 104,
      height: 104,
      color: color.withValues(alpha: 0.15),
      child: const Icon(Icons.person, size: 52, color: Color(0xFF00C853)),
    );
  }
}

// Хедер (заголовок + серия дней)
class _Header extends StatelessWidget {
  final bool isDark;
  final int streak;
  final ThemeData theme;

  const _Header({
    required this.isDark,
    required this.streak,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF151B23) : const Color(0xFFE8ECF1); // Фон хедера
    final red = const Color(0xFFFF1744); // Для огонька и нижней полосы

    return Container(
      width: double.infinity, // На всю ширину
      decoration: BoxDecoration(
        color: bgColor,
        border: Border( // Нижняя граница (тонкая полоса)
          bottom: BorderSide(color: red.withValues(alpha: 0.6), width: 2),
        ),
        boxShadow: [ // Тень снизу
          BoxShadow(
            color: red.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Внутренние отступы
      child: Row(
        children: [
          Text( // Заголовок слева
            'Шагомер Edem Walk',
            style: theme.textTheme.titleMedium?.copyWith( // Переопределяем базовый стиль
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0.3,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(), // Прижимает всё, что после него, вправо
          if (streak > 0) // Плашка с серией
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: red.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFFF1744)),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFFFF1744),
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
// Метрика (круглая иконка + значение)
class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : const Color(0xFF1A1A2E); // Основной цвет текста и иконки
    final subColor =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577); // Цвет обводки

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container( // Круглая обводка с иконкой внутри
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: subColor, width: 2),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text( // Значение под иконкой
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
// Нижняя кнопка
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00C853), Color(0xFF00A844)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withValues(alpha: isDark ? 0.3 : 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577),
            ),
          ),
        ],
      ),
    );
  }
}

// Рисовальщик кольца
class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 ... 1.0
  final bool isDark;

  _ProgressRingPainter(this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2); // Центр круга - середина области
    final radius = size.width / 2 - 15; // Радиус - половина ширины минус половина толщины обводки

    final bgPaint = Paint() // Фоновая обводка
      ..color =
          isDark ? const Color(0xFF1E2A38) : const Color(0xFFD1D9E6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 21;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint() // Прогреесс
      ..color = const Color(0xFF00C853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 21
      ..strokeCap = StrokeCap.round;

    canvas.drawArc( // Рисует дугу 
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.isDark != isDark;
}