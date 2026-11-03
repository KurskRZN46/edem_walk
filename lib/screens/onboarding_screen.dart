import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../services/step_service.dart';
import 'home_screen.dart';

// Онбординг: 3 приветственных слайда + экран запроса разрешения.
// Как только разрешение выдано - автоматически переходим на главный экран.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _requested = false; // Пользователь уже нажал кнопку запроса разрешения?

  // Слайды-презентации возможностей приложения
  static const _slides = [
    (
      icon: Icons.directions_run,
      color: Color(0xFF00C853),
      title: 'Футбольный шагомер',
      text: 'Считает шаги через датчик движения телефона. '
          'Геолокация не нужна — мы не собираем лишних данных.',
    ),
    (
      icon: Icons.sports_soccer,
      color: Color(0xFFFF1744),
      title: 'Нормативы футболистов',
      text: 'Выбери позицию — и сравнивай свои километры с нормативом '
          'вратаря, защитника, полузащитника или нападающего.',
    ),
    (
      icon: Icons.stadium,
      color: Color(0xFF0091EA),
      title: 'Матчи и карьера',
      text: 'Каждые 1500 шагов в матче — гол. Забивай, выигрывай, '
          'расти от Любителя до Легенды и собирай достижения.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>(); // Подписываемся на StepProvider. Когда permissionState изменится, экран перерисуется
    final permState = stepProvider.permissionState; // Текущий статус разрешения
    final cs = Theme.of(context).colorScheme; // Текущая цветовая схема темы
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (permState == PermissionState.granted) { // Автоматический переход на Home, если разрешение уже есть
      WidgetsBinding.instance.addPostFrameCallback((_) { // addPostFrameCallback откладывает переход на после отрисовки кадра
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement( // Заменяем текущий экран на HomeScreen. Именно replacement, а не push, чтобы нельзя было вернуться
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }

    final isLastSlide = _page >= _slides.length; // последняя страница - разрешение

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B0F14) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Слайды
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length + 1, // +1 страница разрешения
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  if (i < _slides.length) {
                    return _IntroSlide(slide: _slides[i], isDark: isDark);
                  }
                  return _buildPermissionPage(stepProvider, permState, cs);
                },
              ),
            ),
            // Индикатор-точки
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length + 1, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF00C853)
                        : (isDark
                            ? const Color(0xFF3A4553)
                            : const Color(0xFFD0D5DD)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Кнопки навигации по слайдам
            if (!isLastSlide)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        child: const Text('Далее'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pageController.animateToPage(
                        _slides.length,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Пропустить'),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 20),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Последняя страница: запрос разрешения на датчик шагов
  Widget _buildPermissionPage(
    StepProvider stepProvider,
    PermissionState permState,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, size: 80, color: Color(0xFFFF1744)), // Иконка бегущего человечка
          const SizedBox(height: 24),
          Text('Осталось разрешение',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF1744),
                  )),
          const SizedBox(height: 16),
          Text( // Описание
            'Приложение считает ваши шаги через датчик движения. '
            'Разрешите доступ, чтобы начать отслеживание.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          if (!_requested) ...[ // Пока пользователь не нажал, показываем кнопку. ...[] раскрывает список виджетов
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  setState(() => _requested = true);
                  await stepProvider.requestPermissions();
                },
                child: const Text('Разрешить доступ к активности'),
              ),
            ),
          ] else ...[ // После нажатия показываем результат
            if (permState == PermissionState.denied) ...[ // Пользователь отказал
              Icon(Icons.warning, size: 48, color: Colors.orange.shade400),
              const SizedBox(height: 16),
              Text(
                'Без доступа к датчику шаги не будут считаться. '
                'Вы можете попробовать снова.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await stepProvider.requestPermissions(); // Повторный запрос разрешения
                  },
                  child: const Text('Попробовать снова'),
                ),
              ),
            ] else if (permState == PermissionState.permanentlyDenied) ...[ // Пользователь отказал навсегда
              Icon(Icons.block, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Доступ запрещён в настройках системы. '
                'Откройте настройки и включите доступ к активности.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await stepProvider.openSystemSettings(); // Открывает системные настройки
                  },
                  child: const Text('Открыть настройки'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await stepProvider.requestPermissions();
                },
                child: const Text('Проверить снова'),
              ),
            ] else if (permState == PermissionState.unknown) ...[ // Идёт запрос
              const CircularProgressIndicator(),
            ],
          ],
        ],
      ),
    );
  }
}

// Один приветственный слайд
class _IntroSlide extends StatelessWidget {
  final ({IconData icon, Color color, String title, String text}) slide;
  final bool isDark;

  const _IntroSlide({required this.slide, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.color.withValues(alpha: 0.12),
              border: Border.all(
                color: slide.color.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(slide.icon, size: 64, color: slide.color),
          ),
          const SizedBox(height: 28),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: slide.color,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? const Color(0xFF8B95A7)
                      : const Color(0xFF5A6577),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
