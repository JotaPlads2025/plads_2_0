import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for User
import '../theme/app_theme.dart';
import '../widgets/neon_widgets.dart'; // Future proofing, though direct usage here is mostly custom cards
import 'login_screen.dart'; // Reuse background painter
import 'register_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final User? googleUser;
  
  const RoleSelectionScreen({super.key, this.googleUser});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          // Reuse Animated Background
          Positioned.fill(
            child: CustomPaint(
              painter: LoginBackgroundPainter(_controller),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Image.asset(
                          'assets/images/logo_app.png',
                          height: 50, // Reduced size
                          fit: BoxFit.contain,
                        ),
                      const Spacer(flex: 2), 
                    ],
                  ),
                  const SizedBox(height: 30), // Reduced spacing
                  
                  const Text(
                    '¿Cómo quieres usar Plads?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26, // Slightly clearer
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige tu perfil para comenzar',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Student Card
                  Expanded(
                    child: _buildRoleCard(
                      context,
                      title: 'Soy Alumno',
                      description: 'Busco clases, talleres y eventos.',
                      icon: Icons.school_outlined,
                      color: AppColors.neonGreen,
                      role: 'student',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Instructor Card
                  Expanded(
                    child: _buildRoleCard(
                      context,
                      title: 'Soy Instructor',
                      description: 'Ofrezco clases y gestiono mis cobros.',
                      icon: Icons.sports_gymnastics,
                      color: AppColors.neonPurple,
                      role: 'instructor',
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required String role}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(initialRole: role, googleUser: widget.googleUser),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceGrey.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade700, size: 16),
          ],
        ),
      ),
    );
  }
}
