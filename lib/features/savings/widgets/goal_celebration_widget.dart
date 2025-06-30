import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays a celebration animation using a CustomPainter on a Canvas.
///
/// This widget is designed to be overlaid on top of other content to celebrate
/// an achievement, such as reaching a savings goal.
class GoalCelebrationWidget extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const GoalCelebrationWidget({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<GoalCelebrationWidget> createState() => _GoalCelebrationWidgetState();
}

class _GoalCelebrationWidgetState extends State<GoalCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CelebrationPainter(animation: _animation),
      child: const SizedBox.expand(),
    );
  }
}

/// A CustomPainter that draws a celebratory starburst/firework animation on a Canvas.
class _CelebrationPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> _colors = [
    Colors.amber,
    Colors.lightGreen,
    Colors.redAccent,
    Colors.lightBlue,
    Colors.purpleAccent
  ];
  final _random = Random();

  _CelebrationPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final progress = animation.value;

    if (progress == 0.0) return;

    // --- Drawing Particles ---
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * pi;
      final distance = progress * size.width * 0.5 * (1 + _random.nextDouble() * 0.4);
      final particleSize = (1 - progress) * (6 + _random.nextDouble() * 4);
      
      final paint = Paint()
        ..color = _colors[i % _colors.length].withAlpha(((1 - progress) * 255).round())
        ..style = PaintingStyle.fill;
        
      final offset = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );
      
      canvas.drawCircle(offset, particleSize, paint);
    }
    
    // --- Drawing Center Glow ---
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(((0.5 * (1 - progress)) * 255).round()),
          Colors.white.withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: progress * 100));

    canvas.drawCircle(center, progress * 100, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
