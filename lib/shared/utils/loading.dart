import 'package:flutter/material.dart';

class GradientFadeSpinner extends StatefulWidget {
  const GradientFadeSpinner({super.key});

  @override
  State<GradientFadeSpinner> createState() => _GradientFadeSpinnerState();
}

class _GradientFadeSpinnerState extends State<GradientFadeSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); // หมุนตลอด
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.1416,
            child: CustomPaint(
              painter: _GradientSpinnerPainter(),
            ),
          );
        },
      ),
    );
  }
}

class _GradientSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 6.28319,
      tileMode: TileMode.clamp,
      colors: [
        Colors.white,
        Colors.grey[400]!,
        Colors.grey[600]!,
        Colors.grey[800]!,
        Colors.black,
      ],
      stops: [0.0, 0.2, 0.4, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      6.28319,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
