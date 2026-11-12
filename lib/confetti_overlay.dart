import 'dart:math';
import 'package:flutter/material.dart';

// Конфетти-оверлей: разовый залп частиц, когда цель достигнута.
// Оборачивает экран: GoalConfetti(active: ..., child: ...).
// Когда active становится true - проигрывается одна анимация.
class GoalConfetti extends StatefulWidget {
  final bool active;
  final Widget child;

  const GoalConfetti({super.key, required this.active, required this.child});

  @override
  State<GoalConfetti> createState() => _GoalConfettiState();
}

class _GoalConfettiState extends State<GoalConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    // Частицы генерируются один раз, чтобы не скакали между кадрами
    final rnd = Random(42);
    _particles = List.generate(48, (_) => _Particle(rnd));
  }

  @override
  void didUpdateWidget(GoalConfetti old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _controller.forward(from: 0); // разовый залп
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.active)
          IgnorePointer( // конфетти не перехватывает нажатия
            child: RepaintBoundary( // рисуется в своём слое - не заставляет перерисовываться экран под конфетти
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(_particles, _controller.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  final double x; // стартовая позиция по горизонтали 0..1
  final double delay; // задержка старта 0..0.3
  final double speed; // скорость падения
  final double size;
  final double wobble; // амплитуда покачивания
  final Color color;

  _Particle(Random rnd)
      : x = rnd.nextDouble(),
        delay = rnd.nextDouble() * 0.3,
        speed = 0.6 + rnd.nextDouble() * 0.5,
        size = 5 + rnd.nextDouble() * 6,
        wobble = rnd.nextDouble() * 0.08,
        color = const [
          Color(0xFF00C853),
          Color(0xFFFF1744),
          Color(0xFF0091EA),
          Color(0xFFFFD600),
          Colors.white,
        ][rnd.nextInt(5)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0.0 - 1.0

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final local = (t - p.delay) / (1 - p.delay);
      if (local <= 0) continue;

      // Падение сверху вниз с небольшим покачиванием
      final dy = local * p.speed * 1.4;
      if (dy > 1.1) continue; // упали за экран
      final dx = p.x + sin(local * 6 + p.x * 10) * p.wobble;

      // Плавное исчезновение в конце
      final opacity = (1 - local).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(dx * size.width, dy * size.height),
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
