import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_config.dart';
import '../data/footballers.dart';

// Экран короткой статьи о футболисте.
// Открывается из экрана аватаров по кнопке «Узнать о футболисте».
class FootballerArticleScreen extends StatelessWidget {
  final Footballer footballer;

  const FootballerArticleScreen({super.key, required this.footballer});

  // Открывает ссылку на коэффициенты во внешнем браузере.
  // canLaunchUrl специально не вызываем: на Android 11+ для неё нужны
  // <queries> в манифесте, а обычный https-запуск работает без них.
  Future<void> _openBettingUrl(BuildContext context) async {
    final uri = Uri.parse(AppConfig.bettingUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context);
      }
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть ссылку')),
    );
  }

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
            // Хедер со стрелкой назад
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
                  Expanded(
                    child: Text(
                      footballer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ЗНАЧОК + ЧИПЫ (без фотографий: чужие портреты - авторские права)
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: green.withValues(alpha: 0.12),
                        border: Border.all(color: green, width: 2.5),
                      ),
                      child: const Icon(Icons.sports_soccer, size: 48, color: green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _chip(footballer.position, green, textMain, borderColor, cardColor),
                      const SizedBox(width: 8),
                      _chip(footballer.country, red, textMain, borderColor, cardColor),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // СТАТЬЯ
                  ...footballer.article.map(
                    (paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        paragraph,
                        style: TextStyle(fontSize: 14, height: 1.55, color: textMain),
                      ),
                    ),
                  ),

                  // ФАКТЫ
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
                          'Коротко',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textMain),
                        ),
                        const SizedBox(height: 8),
                        ...footballer.facts.map(
                          (fact) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.sports_soccer, size: 14, color: green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fact,
                                    style: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // БЛОК КОЭФФИЦИЕНТОВ (отключается в AppConfig.showBettingLink)
                  if (AppConfig.showBettingLink) ...[
                    const SizedBox(height: 20),
                    Divider(color: borderColor),
                    const SizedBox(height: 12),
                    Text(
                      'Хотите узнать, как букмекеры оценивают шансы вашего '
                      'любимого игрока в ближайшей игре?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton.icon(
                        onPressed: () => _openBettingUrl(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Актуальные коэффициенты'),
                        style: FilledButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        AppConfig.bettingDisclaimer,
                        style: TextStyle(fontSize: 10, color: textSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Маленький чип (позиция / страна)
  Widget _chip(String text, Color accent, Color textMain, Color borderColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textMain),
      ),
    );
  }
}
