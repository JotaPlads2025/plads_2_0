import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for User
import 'login_screen.dart'; // Reuse painter
import 'instructor/instructor_home_screen.dart'; // Final destination
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class InterestsScreen extends StatefulWidget {
  final String role;
  final String name;
  final String email;
  final String password;
  final String phone;
  final User? googleUser;

  const InterestsScreen({
    super.key, 
    required this.role,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.googleUser,
  });

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;
  final TextEditingController _customInterestController = TextEditingController();
  
  // Available interests
  final List<String> _interests = [
    // Dance
    'Baile',
    'Salsa',
    'Bachata',
    'Reggaeton',
    'Tango',
    'Hip Hop',
    'Ballet',
    // Fitness
    'Fitness',
    'Calistenia',
    'Pilates',
    'CrossFit',
    'Yoga',
    'Entrenamiento Funcional',
    'Zumba',
    // Other
    'Manualidades',
    'Actividad Física',
    'Salud',
    'Música',
    'Cocina',
    'Fotografía',
  ];

  final Set<String> _selectedInterests = {};

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
    _customInterestController.dispose();
    super.dispose();
  }

  void _addCustomInterest() {
    final custom = _customInterestController.text.trim();
    if (custom.isNotEmpty) {
      setState(() {
        _selectedInterests.add(custom);
        _customInterestController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const neonGreen = Color(0xFF39FF14);
    const neonPurple = Color(0xFFD000FF);
    final accentColor = widget.role == 'instructor' ? neonPurple : neonGreen;

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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                       // Step Indicator 3/3
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentColor),
                        ),
                        child: Text(
                          'Paso 3 de 3',
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                        ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Text(
                    widget.role == 'instructor' ? '¿Qué enseñas?' : '¿Qué te interesa?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                   Text(
                    widget.role == 'instructor' 
                      ? 'Selecciona tus especialidades para que los alumnos te encuentren.'
                      : 'Selecciona tus favoritos para personalizar tu experiencia.',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Custom Input Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customInterestController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Agregar otro (ej: Karate, Costura...)',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addCustomInterest(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: accentColor),
                          onPressed: _addCustomInterest,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid of Interests
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                             // Show ALL selected items first (including custom ones not in list)
                             ..._selectedInterests.where((i) => !_interests.contains(i)).map((interest) {
                                return _buildChip(interest, true, accentColor);
                             }),
                             // Show default list items
                             ..._interests.map((interest) {
                                final isSelected = _selectedInterests.contains(interest);
                                return _buildChip(interest, isSelected, accentColor);
                             }),
                        ],
                      ),
                    ),
                  ),

                  // Finalize Button
                  _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: () async {
                        setState(() { _isLoading = true; });
                        try {
                           final authService = Provider.of<AuthService>(context, listen: false);
                           
                           if (widget.googleUser != null) {
                             // Social Registration (User already authenticated in Firebase)
                             await authService.registerFromSocial(
                               uid: widget.googleUser!.uid,
                               email: widget.email,
                               name: widget.name,
                               role: widget.role,
                               interests: _selectedInterests.toList(),
                             );
                           } else {
                             // Traditional Registration (Full create)
                             await authService.register(
                               email: widget.email,
                               password: widget.password,
                               name: widget.name,
                               role: widget.role,
                               acceptedTerms: true,
                               interests: _selectedInterests.toList(),
                             );
                           }
                           
                           Navigator.of(context).popUntil((route) => route.isFirst); 
                        } catch (e) {
                           setState(() { _isLoading = false; });
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al registrar: $e'), backgroundColor: Colors.red),
                          );
                        }
                    },
                     style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'FINALIZAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
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

  Widget _buildChip(String label, bool isSelected, Color accentColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedInterests.remove(label);
          } else {
            _selectedInterests.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade800,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
