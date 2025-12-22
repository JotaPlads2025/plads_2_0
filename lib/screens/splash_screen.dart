import 'package:flutter/material.dart';
import 'dart:math' as math;
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
      duration: const Duration(seconds: 3),
    )..repeat();

    // Navigate to Login after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
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
    return Scaffold(
      backgroundColor: Colors.black,
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
                  'assets/images/logo_plads_oficial.png', // Or 'assets/images/logo_app.png' depending on preference
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

    // Neon Green Path
    paint.color = const Color(0xFF39FF14); // Neon Green
    _drawWave(canvas, size, paint, offset: 0.0, speed: 1.0);

    // Neon Purple Path
    paint.color = const Color(0xFFD000FF); // Neon Purple
    _drawWave(canvas, size, paint, offset: 50.0, speed: 0.8);
    
    // Another Green Path (Lower)
     paint.color = const Color(0xFF39FF14).withOpacity(0.5);
    _drawWave(canvas, size, paint, offset: 150.0, speed: 1.2, verticalShift: 200);

     // Another Purple Path (Lower)
     paint.color = const Color(0xFFD000FF).withOpacity(0.5);
    _drawWave(canvas, size, paint, offset: 200.0, speed: 0.9, verticalShift: 200);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, {double offset = 0, double speed = 1.0, double verticalShift = 0}) {
    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width / 1.5;
    
    // Dynamic shift based on animation
    final animationShift = animation.value * size.width * speed;

    path.moveTo(0, size.height / 2 + verticalShift);

    for (double x = 0; x <= size.width; x++) {
      final y = math.sin((x + animationShift + offset) / waveLength * 2 * math.pi) * waveHeight + (size.height / 2) + verticalShift;
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
    return true; // Repaint on animation frame
  }
}
