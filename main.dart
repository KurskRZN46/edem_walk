// Вот он. Момент с которого всё началось. Точка отсчёта.

import 'dart:async'; // Timer для периодической синхронизации напоминаний
import 'package:flutter/material.dart'; // UI-компоненты Material
import 'package:flutter/services.dart'; // SystemChrome (ориентация экрана)
import 'package:provider/provider.dart'; // Провайдеры (передача данных между экранами)
import 'package:hive_flutter/hive_flutter.dart'; // Hive (локальная база)
import 'services/storage_service.dart'; // Наш сервис хранения (Hive + SharedPreferences)
import 'services/step_service.dart'; // Наш сервис шагомера
import 'providers/step_provider.dart'; // Провайдер шагов
import 'providers/normative_provider.dart'; // Провайдер футбольного норматива (выбранная позиция)
import 'providers/match_provider.dart'; // Провайдер режима «Матч»
import 'providers/career_provider.dart'; // Провайдер карьеры и достижений
import 'providers/avatar_provider.dart'; // Провайдер выбранного аватара
import 'providers/workout_provider.dart'; // Провайдер интервальных тренировок
import 'services/notification_service.dart'; // Локальные напоминания (пуши)
import 'screens/onboarding_screen.dart'; // Первый экран (запрос разрешений, объяснение)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([ // Нам альбом не нужен
    DeviceOrientation.portraitUp,
  ]);
  await Hive.initFlutter(); // Инициализация локал. бд
  await StorageService.init(); // Наш сервис хранения

  final stepService = StepService(); // Создаём сервис шагомера
  await stepService.init();

  // Инициализируем напоминания и планируем пуши под текущее состояние
  await NotificationService.init();
  await NotificationService.syncAll(
    steps: stepService.todaySteps,
    goal: stepService.dailyGoal,
    streakDays: stepService.streakDays,
  );
  // Пока приложение открыто, каждые 15 минут обновляем вечерний пуш
  // (чтобы «осталось N шагов» было актуальным)
  Timer.periodic(const Duration(minutes: 15), (_) {
    NotificationService.syncAll(
      steps: stepService.todaySteps,
      goal: stepService.dailyGoal,
      streakDays: stepService.streakDays,
    );
  });

  // Запускаем приложение с провайдерами
  runApp(
    // Обёртка, позволяющая разместить несколько провайдеров
    MultiProvider(
      providers: [
        // Провайдер шагов. Оборачивает stepService. Когда сервис вызывает notifyListeners(), то все виджеты, которые слушают StepProvider, перерисовываются
        ChangeNotifierProvider<StepProvider>(
          create: (_) => StepProvider(stepService),
        ),
        // Провайдер нормативов. Загружает выбранную позицию из локального хранилища
        ChangeNotifierProvider<NormativeProvider>(
          create: (_) => NormativeProvider()..loadPosition(),
        ),
        // Провайдер матча. Восстанавливает незавершённый матч при запуске
        ChangeNotifierProvider<MatchProvider>(
          create: (_) => MatchProvider(stepService)..init(),
        ),
        // Провайдер карьеры. Читает статистику матчей из хранилища
        ChangeNotifierProvider<CareerProvider>(
          create: (_) => CareerProvider()..init(),
        ),
        // Провайдер аватара. Загружает выбранный аватар из хранилища
        ChangeNotifierProvider<AvatarProvider>(
          create: (_) => AvatarProvider()..loadAvatar(),
        ),
        // Провайдер тренировок. Загружает статистику и настройки плана
        ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => WorkoutProvider(stepService)..init(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Корневой виджет приложения
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // build вызывается при создании/перерисовке виджета
  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>();
    return MaterialApp(
      title: 'Edem Walk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light, // тема
          primary: Color(0xFF00C853), // главный акцент
          onPrimary: Color(0xFFFFFFFF), // текст поверх главного акцента
          secondary: Color(0xFF0091EA), // второстепенный
          onSecondary: Color(0xFFFFFFFF),
          surface: Color(0xFFF8F9FB), // фон темы
          onSurface: Color(0xFF0B0F14), // текст на фоне
          onSurfaceVariant: Color(0xFF5A6577), // второстепенный текст
          surfaceContainerHighest: Color(0xFFE8ECF1), // карточки, плашки
          primaryContainer: Color(0xFFD7FFE6), // контейнеры
          onPrimaryContainer: Color(0xFF003D1F),
          outlineVariant: Color(0xFFD0D5DD), // границы
          error: Color(0xFFD32F2F), // ошибки
          onError: Color(0xFFFFFFFF),
        ),
        useMaterial3: true, // новый дизайн (скруглённые углы, другие тени)
        // Красивые переходы между экранами: zoom на Android, свайп на iOS
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF00FF87),
          onPrimary: Color(0xFF0B0F14),
          secondary: Color(0xFF00B0FF),
          onSecondary: Color(0xFF0B0F14),
          surface: Color(0xFF0B0F14),
          onSurface: Color(0xFFFFFFFF),
          onSurfaceVariant: Color(0xFF8B95A7),
          surfaceContainerHighest: Color(0xFF151B23),
          primaryContainer: Color(0xFF102218),
          onPrimaryContainer: Color(0xFF00FF87),
          outlineVariant: Color(0xFF1E2730),
          error: Color(0xFFFF1744),
          onError: Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: stepProvider.themeMode, // тема выбирается по системной настройке телефона
      home: const OnboardingScreen(),
    );
  }
}
