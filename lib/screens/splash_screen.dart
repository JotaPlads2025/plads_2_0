import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          // Background Waves
          Positioned.fill(
            child: CustomPaint(
              painter: WavyBackgroundPainter(_controller),
            ),
          ),
          // Centered Logo
          Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Image.asset(
                  'assets/images/largo_verde.png', 
                  width: 250, 
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WavyBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  WavyBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Top Waves
    paint.color = AppColors.neonGreen.withOpacity(0.8);
    _drawWave(canvas, size, paint, offset: 0.0, speed: 1.0, basePath: size.height * 0.15); // Top 15%

    paint.color = AppColors.neonPurple.withOpacity(0.8);
    _drawWave(canvas, size, paint, offset: 50.0, speed: 0.8, basePath: size.height * 0.20); // Top 20%
    
    // Bottom Waves
    paint.color = AppColors.neonGreen.withOpacity(0.6);
    _drawWave(canvas, size, paint, offset: 150.0, speed: 1.2, basePath: size.height * 0.80); // Bottom 80%

     paint.color = AppColors.neonPurple.withOpacity(0.6);
    _drawWave(canvas, size, paint, offset: 200.0, speed: 0.9, basePath: size.height * 0.85); // Bottom 85%
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, {double offset = 0, double speed = 1.0, required double basePath}) {
    final path = Path();
    final waveHeight = 25.0; // Slightly larger waves
    final waveLength = size.width / 1.2;
    
    // Dynamic shift based on animation
    final animationShift = animation.value * size.width * speed;

    path.moveTo(0, basePath);

    for (double x = 0; x <= size.width; x++) {
      final y = math.sin((x + animationShift + offset) / waveLength * 2 * math.pi) * waveHeight + basePath;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavyBackgroundPainter oldDelegate) {
    return true; 
  }
}
