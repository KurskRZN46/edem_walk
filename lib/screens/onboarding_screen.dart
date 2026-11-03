import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../services/step_service.dart';
import 'home_screen.dart';

// StatefulWidget, потому что есть изменяемое состояние, которое меняется при нажатии кнопки
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// Хранит состояние виджета и переживает перерисовки
class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _requested = false; // Пользователь уже нажал кнопку запроса разрешения?

  @override
  Widget build(BuildContext context) {
    final stepProvider = context.watch<StepProvider>(); // Подписываемся на StepProvider. Когда permissionState изменится, экран перерисуется
    final permState = stepProvider.permissionState; // Текущий статус разрешения
    final cs = Theme.of(context).colorScheme; // Текущая цветовая схема темы

    if (permState == PermissionState.granted) { // Автоматический переход на Home, если разрешение уже есть
      WidgetsBinding.instance.addPostFrameCallback((_) { // addPostFrameCallback откладывает переход на после отрисовки кадра
        Navigator.of(context).pushReplacement( // Заменяем текущий экран на HomeScreen. Именно replacement, а не push, чтобы нельзя было веренуться
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }
    // Каркас экрана
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_run, size: 80, color: const Color(0xFFFF1744)), // Иконка бегущего человечка
              const SizedBox(height: 24),
              Text('Футбольный шагомер',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
        ),
      ),
    );
  }
}