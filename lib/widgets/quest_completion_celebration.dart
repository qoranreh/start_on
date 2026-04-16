import 'dart:math' as math;

import 'package:flutter/material.dart';

class QuestCompletionCelebration extends StatefulWidget {
  const QuestCompletionCelebration({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  final int seed;
  final VoidCallback onComplete;

  @override
  State<QuestCompletionCelebration> createState() =>
      _QuestCompletionCelebrationState();
}

class _QuestCompletionCelebrationState extends State<QuestCompletionCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onComplete();
          }
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _QuestCelebrationPainter(
              progress: _controller.value,
              seed: widget.seed,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _QuestCelebrationPainter extends CustomPainter {
  const _QuestCelebrationPainter({required this.progress, required this.seed});

  final double progress;
  final int seed;

  static const _colors = [
    Color(0xFFFF8B93),
    Color(0xFFFFD97D),
    Color(0xFFAED7FF),
    Color(0xFF78E49B),
    Color(0xFFFFC857),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final leftOrigin = Offset(size.width * 0.5 - 34, size.height - 18);
    final rightOrigin = Offset(size.width * 0.5 + 34, size.height - 18);

    _paintBurst(canvas, size, random, leftOrigin, -1);
    _paintBurst(canvas, size, random, rightOrigin, 1);
    _paintGlow(canvas, leftOrigin);
    _paintGlow(canvas, rightOrigin);
  }

  void _paintBurst(
    Canvas canvas,
    Size size,
    math.Random random,
    Offset origin,
    int horizontalBias,
  ) {
    const particleCount = 22;
    for (var index = 0; index < particleCount; index++) {
      final spread = 0.18 + random.nextDouble() * 0.92;
      final localProgress = ((progress - (index * 0.008)) / 0.92).clamp(
        0.0,
        1.0,
      );
      if (localProgress <= 0) {
        continue;
      }

      final angle =
          (-math.pi / 2) +
          (horizontalBias * 0.22) +
          ((random.nextDouble() - 0.5) * 1.3);
      final distance = 32 + random.nextDouble() * 116;
      final velocity = distance * Curves.easeOut.transform(localProgress);
      final gravity = 58 * localProgress * localProgress;
      final dx = math.cos(angle) * velocity * spread;
      final dy = math.sin(angle) * velocity * spread;
      final position = Offset(origin.dx + dx, origin.dy + dy + gravity);
      final opacity = (1 - Curves.easeIn.transform(localProgress)).clamp(
        0.0,
        1.0,
      );
      final radius = 2.8 + random.nextDouble() * 3.6;
      final color = _colors[index % _colors.length].withValues(alpha: opacity);

      final paint = Paint()..color = color;
      canvas.drawCircle(position, radius, paint);

      final streakPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final streakEnd = Offset(
        position.dx - (math.cos(angle) * 8),
        position.dy - (math.sin(angle) * 8),
      );
      canvas.drawLine(position, streakEnd, streakPaint);
    }
  }

  void _paintGlow(Canvas canvas, Offset origin) {
    final glowOpacity = (1 - progress).clamp(0.0, 1.0) * 0.35;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD97D).withValues(alpha: glowOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: 46));
    canvas.drawCircle(origin, 46, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _QuestCelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}
