import 'package:flutter/material.dart';
import '../data/footballers.dart';
import 'footballer_article_screen.dart';

// Экран «Футболисты»: список игроков без фотографий
// (чужие портреты - авторские права, такие аватарки не пропустят сторы).
// Тап по карточке открывает короткую статью о футболисте.
class FootballersScreen extends StatelessWidget {
  const FootballersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF00C853);
    const red = Color(0xFFFF1744);

    final cardColor = isDark ? const Color(0xFF151B23) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final textMain = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8B95A7) : const Color(0xFF5A6577);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Хедер со стрелкой назад (единый стиль приложения)
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
                    'Футболисты',
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
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: footballers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final f = footballers[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FootballerArticleScreen(footballer: f),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Значок вместо фото
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: green.withValues(alpha: 0.12),
                            ),
                            child: const Icon(Icons.sports_soccer, size: 26, color: green),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${f.position} · ${f.country}',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          // Кнопка перехода к статье
                          Text(
                            'Узнать\nо футболисте',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: green,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 20, color: textSecondary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
