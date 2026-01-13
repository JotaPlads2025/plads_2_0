import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for User
import '../theme/app_theme.dart';
import '../widgets/neon_widgets.dart';
import 'login_screen.dart'; // Using the painter from LoginScreen
import 'interests_screen.dart';
import 'legal/terms_screen.dart';
import 'legal/privacy_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String initialRole;
  final User? googleUser;

  const RegisterScreen({super.key, required this.initialRole, this.googleUser});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  late AnimationController _controller;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  late String _selectedRole;

  bool get _isSocialLogin => widget.googleUser != null;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
    )..repeat();

    if (_isSocialLogin) {
      _nameController.text = widget.googleUser!.displayName ?? '';
      _emailController.text = widget.googleUser!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          // Reuse Painter from Login (ensure LoginScreen is imported)
          // Ideally move this to a shared widget file, but for now importing works
          Positioned.fill(
              child: CustomPaint(
                painter: LoginBackgroundPainter(_controller),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                       Image.asset(
                          'assets/images/logo_app.png',
                          height: 50, // Reduced
                          fit: BoxFit.contain,
                        ),
                       const SizedBox(width: 48), // Balance
                    ],
                  ),
                  const SizedBox(height: 20), // Reduced

                  // Title
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28, // Compact
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Únete a la comunidad Plads',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Name Input
                  NeonTextField(
                    controller: _nameController,
                    label: 'Nombre Completo',
                    icon: Icons.person_outline,
                    accentColor: AppColors.neonGreen,
                  ),
                  const SizedBox(height: 12),

                  // Email Input
                  NeonTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                    accentColor: AppColors.neonGreen,
                    readOnly: _isSocialLogin, // Cannot edit email if social login
                  ),
                  const SizedBox(height: 12),

                   // Phone Input
                  NeonTextField(
                    controller: _phoneController,
                    label: 'Teléfono (Opcional)',
                    icon: Icons.phone_android_outlined,
                    accentColor: AppColors.neonGreen,
                    // keybordType not exposed in NeonTextField wrapper yet, might need to add it or ignore for now
                  ),
                  const SizedBox(height: 12),

                  // Password fields hidden if social login
                  if (!_isSocialLogin) ...[
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
                    const SizedBox(height: 12),

                    // Confirm Password Input
                    NeonTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar Contraseña',
                      icon: Icons.lock_outline,
                      accentColor: AppColors.neonPurple,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                       onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Legal Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        activeColor: AppColors.neonGreen,
                        side: const BorderSide(color: Colors.white70),
                        onChanged: (val) {
                          setState(() {
                            _acceptedTerms = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text('Acepto los ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                              child: const Text('Términos y Condiciones', style: TextStyle(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            ),
                            const Text(' y la ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                              child: const Text('Política de Privacidad', style: TextStyle(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            ),
                            const Text('.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Register Button
                  NeonButton(
                    text: 'CONTINUAR',
                    onPressed: () {
                       if (!_acceptedTerms) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Debes aceptar los Términos y Condiciones para continuar')),
                         );
                         return;
                       }
                       
                        if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
                         );
                         return;
                       }

                       if (!_isSocialLogin) {
                          if (_passwordController.text.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Por favor ingresa una contraseña')),
                             );
                             return;
                          }
                          if (_passwordController.text != _confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Las contraseñas no coinciden')),
                            );
                            return;
                          }
                       }

                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterestsScreen(
                            role: _selectedRole,
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(), // Can be empty if social
                            phone: _phoneController.text.trim(),
                            googleUser: widget.googleUser, // Pass google user
                          ),
                        ),
                      );
                    },
                    color: AppColors.neonPurple,
                  ),
                   const SizedBox(height: 20),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Inicia Sesión',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
