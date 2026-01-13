import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_widgets.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/custom_exceptions.dart'; // Added
import 'register_screen.dart';
import 'instructor/instructor_home_screen.dart';
import 'student/student_main_screen.dart';
import 'role_selection_screen.dart';

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
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
           // Animated Background
          Positioned.fill(
              child: CustomPaint(
                painter: LoginBackgroundPainter(_controller),
              ),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Reduced vertical padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min, // Compact Layout
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo_app.png',
                        height: 90, // Reduced from 120
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30), // Reduced from 60

                    // Title
                    const Text(
                      'Bienvenid@',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28, // Reduced from 32
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30), // Reduced from 40

                    // Email Input
                    NeonTextField(
                      controller: _emailController,
                      label: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                      accentColor: AppColors.neonGreen,
                    ),
                    const SizedBox(height: 16), // Reduced from 20

                    // Password Input
                    NeonTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      accentColor: AppColors.neonPurple,
                      isPassword: true,
                      obscureText: _obscurePassword,
                       onToggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Forgot Password logic
                        },
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30), // Reduced from 40

                    // Login Button (General)
                    NeonButton(
                      text: 'INGRESAR',
                      onPressed: () async {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor ingresa correo y contraseña')),
                            );
                            return;
                          }

                          try {
                            // AuthService will handle the logic and AuthWrapper will redirect
                            // We just wait for completion clearly
                            await Provider.of<AuthService>(context, listen: false).signIn(email, password);
                            
                            // No navigation needed here, AuthWrapper detects change
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al ingresar: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                      },
                      color: AppColors.neonGreen,
                    ),
                    // Removed separate buttons for testing. Roles are now handled by AuthWrapper.
                    const SizedBox(height: 20),

                    // --- Google Sign In ---
                    Row(children: [
                      Expanded(child: Divider(color: Colors.grey.shade800)),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('O', style: TextStyle(color: Colors.grey))),
                      Expanded(child: Divider(color: Colors.grey.shade800)),
                    ]),
                    const SizedBox(height: 20),
                    
                    OutlinedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                      label: const Text('Continuar con Google', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                      onPressed: () async {
                           try {
                             await Provider.of<AuthService>(context, listen: false).signInWithGoogle();
                             // Navigation handled by auth wrapper
                           } on NewUserException catch (e) {
                             // User Authenticated but not Registered in Firestore
                             Navigator.push(
                               context, 
                               MaterialPageRoute(
                                 builder: (context) => RoleSelectionScreen(googleUser: e.user),
                               ),
                             );
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text('Error: $e'),
                                 backgroundColor: Colors.red,
                               ),
                             );
                           }
                      },
                    ),

                    const SizedBox(height: 30),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta? ',
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                             // Go directly to Role Selection
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                            );
                          },
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: AppColors.neonPurple,
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
          ),
        ],
      ),
    );
  }
}

// Custom Painter for animated background (Waves/Nebula effect)
class LoginBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  LoginBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Base background is already black/dark from Scaffold
    
    // Draw some moving blurred circles/blobs
    final time = animation.value * 2 * math.pi;

    _drawBlob(canvas, size, time, Colors.deepPurple.withOpacity(0.2), 0.3, 0.4, 150);
    _drawBlob(canvas, size, time + 2, Colors.green.withOpacity(0.15), 0.7, 0.2, 200);
    _drawBlob(canvas, size, time + 4, Colors.blue.withOpacity(0.15), 0.2, 0.8, 180);
  }

  void _drawBlob(Canvas canvas, Size size, double time, Color color, double xFactor, double yFactor, double radius) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60); // Heavy blur for neon glow

    final dx = size.width * xFactor + math.sin(time) * 30;
    final dy = size.height * yFactor + math.cos(time * 0.7) * 40;

    canvas.drawCircle(Offset(dx, dy), radius, paint);
  }

  @override
  bool shouldRepaint(covariant LoginBackgroundPainter oldDelegate) {
     return true;
  }
}
