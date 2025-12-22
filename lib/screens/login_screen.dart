import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _controller;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Neon colors from Splash
    final neonGreen = const Color(0xFF39FF14);
    const neonPurple = Color(0xFFD000FF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
           // Animated Background
          Positioned.fill(
              child: CustomPaint(
                painter: LoginBackgroundPainter(_controller),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo_plads_oficial.png',
                      height: 120, // Adjusted size
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Title
                  const Text(
                    'Bienvenid@',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email Input
                  _buildNeonInput(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                    color: neonGreen,
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  _buildNeonInput(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    color: neonPurple, // Alternate accent color
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to Forgot Password
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Login Logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonGreen,
                      foregroundColor: Colors.black, // Text color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: neonGreen.withOpacity(0.4),
                    ),
                    child: const Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
            
                  // Divider
                  const Row(
                    children: [
                       Expanded(child: Divider(color: Colors.grey)),
                       Padding(
                         padding: EdgeInsets.symmetric(horizontal: 16),
                         child: Text('O continúa con', style: TextStyle(color: Colors.grey)),
                       ),
                       Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Social Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(
                        icon: Icons.g_mobiledata, // Placeholder for Google Logo
                        label: 'Google',
                        onTap: () {
                          // TODO: Implement Google Sign In
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configuración de Google pendiente')),
                          );
                        },
                      ),
                      _buildSocialButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onTap: () {
                          // TODO: Implement Facebook Sign In
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configuración de Facebook pendiente')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Sign Up
                        },
                        child: Text(
                          'Regístrate',
                          style: TextStyle(
                            color: neonPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      cursorColor: color,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: color),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade900,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade900,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  LoginBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
     final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Top Right Corner (Purple)
    paint.color = const Color(0xFFD000FF).withOpacity(0.4);
    _drawCornerWave(canvas, size, paint, isTop: true);

    // Bottom Left Corner (Green)
    paint.color = const Color(0xFF39FF14).withOpacity(0.4);
    _drawCornerWave(canvas, size, paint, isTop: false);
  }

  void _drawCornerWave(Canvas canvas, Size size, Paint paint, {required bool isTop}) {
    final path = Path();
    final time = animation.value * 2 * math.pi;
    
    // Diagonal drawing logic
    if (isTop) {
        for (double i = 0; i < 200; i++) {
           final x = size.width - i;
           final y = (i * 0.5) + math.sin((i / 30) + time) * 10;
           if (i==0) path.moveTo(size.width, 0);
           path.lineTo(x, y);
        }
    } else { // Bottom Left
        for (double i = 0; i < 200; i++) {
            final x = i;
            final y = size.height - (i * 0.5) + math.sin((i / 30) + time) * 10;
            if (i==0) path.moveTo(0, size.height);
            path.lineTo(x, y);
        }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LoginBackgroundPainter oldDelegate) => true;
}
