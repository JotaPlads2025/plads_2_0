import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StudentClassDetailScreen extends StatelessWidget {
  final Map<String, dynamic> classData;

  const StudentClassDetailScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFD000FF);
    final secondaryColor = const Color(0xFF39FF14);
    final cardColor = Theme.of(context).cardTheme.color;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                classData['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  classData['image'].startsWith('http') 
                      ? Image.network(classData['image'], fit: BoxFit.cover)
                      : Container(color: Colors.grey),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(classData['instructor'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              Text(' ${classData['rating']} (${classData['reviews']} reseñas)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Text(
                          classData['category'],
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Grid
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(context, Icons.calendar_today, 'Horario', 'Lun - Mié\n19:00 hrs')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard(context, Icons.location_on, 'Ubicación', 'Providencia\nEstudio A')),
                    ],
                  ),
                  const SizedBox(height: 12),
                   Row(
                    children: [
                       Expanded(child: _buildInfoCard(context, Icons.people, 'Cupos', '${classData['availability']} disponibles')),
                       const SizedBox(width: 12),
                       Expanded(child: _buildInfoCard(context, Icons.attach_money, 'Precio', '\$${classData['price']}')),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Plans Section
                  if (classData['plans'] != null && (classData['plans'] as List).isNotEmpty) ...[
                     const Text('Planes Disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                     ...(classData['plans'] as List).map((plan) => Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: cardColor,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.grey.withOpacity(0.1)),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(plan['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                           Text('\$${plan['price']}', style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor)),
                         ],
                       ),
                     )),
                     const SizedBox(height: 24),
                  ],

                  const Text('Sobre la clase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Esta clase está diseñada para todos los niveles. Aprenderás técnica, musicalidad y conexión en pareja. No necesitas venir con pareja.',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), height: 1.5),
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: classData['availability'] > 0 
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flujo de Pago Simple (Próximamente)')));
                            } 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text(classData['availability'] > 0 ? 'Inscribirse Ahora' : 'Lista de Espera'),
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

  Widget _buildInfoCard(BuildContext context, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
