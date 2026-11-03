import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/position_norms.dart';
import '../providers/normative_provider.dart';
import '../providers/step_provider.dart';

// Экран «Нормативы футболиста».
// Пользователь выбирает позицию, видит, сколько километров за матч
// пробегает средний игрок этой позиции, и сравнивает со своим
// километражом за сегодня (его считает шагомер - StepProvider.km).
class NormativesScreen extends StatelessWidget {
  const NormativesScreen({super.key});

  // Иконка для каждой позиции
  IconData _iconFor(String id) {
    switch (id) {
      case 'goalkeeper':
        return Icons.sports_handball; // вратарь - руки
      case 'defender':
        return Icons.shield; // защитник - щит
      case 'midfielder':
        return Icons.autorenew; // полузащитник - связующее звено
      case 'forward':
        return Icons.bolt; // нападающий - молния (спринты)
      default:
        return Icons.sports_soccer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);

    final normativeProvider = context.watch<NormativeProvider>();
    final stepProvider = context.watch<StepProvider>();

    final norm = normativeProvider.selected;
    final myKm = stepProvider.km; // километры пользователя за сегодня
    final target = norm.targetKm; // средняя норма выбранной позиции
    final progress = target > 0 ? (myKm / target).clamp(0.0, 1.0) : 0.0;
    final percent = target > 0 ? (myKm / target * 100).round() : 0;

    // Мотивационная подпись в зависимости от прогресса
    final String statusText;
    if (progress >= 1.0) {
      statusText = 'Матч сыгран! Сегодня вы на уровне ${norm.nameGenitive}.';
    } else if (progress >= 0.5) {
      statusText = 'Второй тайм! Осталось ${(target - myKm).toStringAsFixed(1)} км до норматива.';
    } else if (myKm > 0) {
      statusText = 'Пока разминка. Норматив ${norm.nameGenitive} - $target км за матч.';
    } else {
      statusText = 'Запустите шагомер и выйдите на поле. Норматив ${norm.nameGenitive} - $target км.';
    }

    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textMain = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Хедер со стрелкой назад (стиль как на экране аватаров)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151B23) : const Color(0xFFE8ECF1),
                border: Border(bottom: BorderSide(color: red.withValues(alpha: 0.6), width: 2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textMain),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Нормативы футболиста',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: textMain,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Выберите позицию',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSecondary),
                  ),
                  const SizedBox(height: 12),

                  // СЕТКА ПОЗИЦИЙ 2x2
                  GridView.builder(
                    shrinkWrap: true, // сетка внутри ListView - занимает только нужную высоту
                    physics: const NeverScrollableScrollPhysics(), // скроллит внешний ListView
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: positionNorms.length,
                    itemBuilder: (context, index) {
                      final p = positionNorms[index];
                      final isSelected = p.id == norm.id;
                      return GestureDetector(
                        onTap: () => normativeProvider.selectPosition(p), // сохраняем выбор
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected ? green.withValues(alpha: 0.10) : cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? green : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(_iconFor(p.id), size: 26, color: isSelected ? green : textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? green : textMain,
                                      ),
                                    ),
                                    Text(
                                      p.rangeLabel,
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // КАРТОЧКА НОРМАТИВА
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sports_soccer, color: red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Сколько бегает ${norm.nameGenitive}',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textMain),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          norm.rangeLabel + ' за матч',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: green,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${norm.description}\nЭто примерно ${norm.targetSteps} шагов.',
                          style: TextStyle(fontSize: 13, height: 1.45, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // КАРТОЧКА СРАВНЕНИЯ С ПОЛЬЗОВАТЕЛЕМ
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Вы сегодня',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textMain),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              myKm.toStringAsFixed(2),
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: textMain),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'км из ${target.toStringAsFixed(1)} км',
                              style: TextStyle(fontSize: 14, color: textSecondary),
                            ),
                            const Spacer(),
                            Text(
                              '$percent%',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Полоса прогресса
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: isDark ? const Color(0xFF1E2730) : const Color(0xFFE8ECF1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 ? red : green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Сноска про методику
                  Text(
                    'Дистанция считается по вашим шагам за сегодня (0,75 м на шаг). '
                    'Цифры нормативов - усреднённые значения профессионального футбола.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: textSecondary),
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
