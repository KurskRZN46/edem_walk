import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/avatars.dart';
import '../providers/avatar_provider.dart';

// Экран выбора аватара профиля.
// Все аватары - авторские стилизованные персонажи, сгенерированные
// специально для приложения (не реальные футболисты, без проблем с правами).
class AvatarsScreen extends StatefulWidget {
  const AvatarsScreen({super.key});

  @override
  State<AvatarsScreen> createState() => _AvatarsScreenState();
}

class _AvatarsScreenState extends State<AvatarsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Заранее декодируем все аватары в фоне - сетка открывается без подёргиваний
    for (final avatar in playerAvatars) {
      precacheImage(AssetImage(avatar.asset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = context.watch<AvatarProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const green = Color(0xFF00C853);
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
            _AvatarsHeader(isDark: isDark, theme: theme),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                'Выбери своего игрока — он будет в центре главного экрана',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subColor),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: playerAvatars.length,
                itemBuilder: (context, i) {
                  final avatar = playerAvatars[i];
                  final isSelected = avatarProvider.selected.id == avatar.id;
                  return GestureDetector(
                    onTap: () {
                      avatarProvider.selectAvatar(avatar.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Аватар: ${avatar.name}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? green.withValues(alpha: isDark ? 0.18 : 0.1)
                            : cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? green : borderColor,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: green.withValues(alpha: 0.08),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    avatar.asset,
                                    cacheWidth: 288, // Декодируем под реальный размер (96 * 3) - быстрее и меньше памяти
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.sports_soccer,
                                      size: 48,
                                      color: green,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundColor: green,
                                    child: Icon(Icons.check,
                                        size: 15, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            avatar.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            avatar.title,
                            style: TextStyle(fontSize: 11.5, color: subColor),
                          ),
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

// Хедер экрана аватаров
class _AvatarsHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _AvatarsHeader({required this.isDark, required this.theme});

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
            'Аватар',
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
