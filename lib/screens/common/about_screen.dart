import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Official Gradient
    final gradient = LinearGradient(
      colors: [Color(0xFF5436BB), Color(0xFF321C96)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // 1. Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 40, left: 24, right: 24),
              decoration: BoxDecoration(gradient: gradient),
              child: Column(
                children: [
                   // Logo Placeholder (Safety Area respected)
                   Container(
                     margin: const EdgeInsets.only(bottom: 24),
                     height: 80,
                     child: Image.asset('assets/images/logo_app.png', fit: BoxFit.contain), // Ensure asset exists or use placeholder logic if needed, usually we have text fallback
                   ),
                   const Text(
                     '"Conectamos a quienes quieren aprender con quienes aman enseñar."',
                     textAlign: TextAlign.center,
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 18,
                       fontStyle: FontStyle.italic,
                       fontWeight: FontWeight.w300,
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Text(
                     'Somos PLADS',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 28,
                       fontWeight: FontWeight.bold,
                       letterSpacing: 1.2,
                     ),
                   ),
                   const SizedBox(height: 8),
                   const Text(
                     'Tu Plataforma de Arte, Deporte y Salud.',
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.white70, fontSize: 14),
                   ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Mission
                  _buildSectionTitle('Nuestra Misión', isDark),
                  const Text(
                    'Nacimos con un objetivo claro: digitalizar y profesionalizar el bienestar en América Latina.',
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Para ti (Usuario): Un espacio seguro y fácil para encontrar tu pasión.'),
                  _buildBulletPoint('Para el Profesor: Tecnología para dejar de administrar y empezar a enseñar.'),
                  
                  const SizedBox(height: 32),

                  // 3. Pillars
                  _buildSectionTitle('Nuestros Pilares', isDark),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPillarCircle(Color(0xFF9C27B0), 'Arte', Icons.palette), // Purple
                      _buildPillarCircle(Color(0xFF2196F3), 'Deporte', Icons.fitness_center), // Blue
                      _buildPillarCircle(Color(0xFF4CAF50), 'Salud', Icons.spa), // Green
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 4. Founders
                  _buildSectionTitle('Nuestra Historia y Equipo', isDark),
                  const Text(
                    'PLADS nació de la experiencia real para transformar el caos en comunidad.',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildFounderCard(context, 'Claudia Bravo', 'Cofundadora y Visionaria del Bienestar'),
                  _buildFounderCard(context, 'José Ballesteros', 'Cofundador y Experto en Ecosistemas Digitales'),
                  const SizedBox(height: 16),
                  const Text(
                    'Apoyamos a profesores independientes y academias que merecen brillar, llenando el vacío tecnológico en la región.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 32),

                  // 5. Why Plads
                  _buildSectionTitle('¿Por qué Plads?', isDark),
                  _buildFeatureRow(Icons.check_circle_outline, 'Sin barreras', 'Adiós a la coordinación manual.'),
                  _buildFeatureRow(Icons.verified_outlined, 'Confianza', 'Instructores verificados.'),
                  _buildFeatureRow(Icons.trending_up, 'Crecimiento', 'Gestión profesional para instructores.'),

                  const SizedBox(height: 40),
                  
                  // CTA
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF5436BB).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                        ]
                      ),
                      child: const Text(
                        'Descubre. Reserva. Paga. ¡Empieza a Moverte!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.neonPurple),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildPillarCircle(Color color, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildFounderCard(BuildContext context, String name, String role) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
