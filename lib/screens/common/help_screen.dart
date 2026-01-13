import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y Soporte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preguntas Frecuentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFAQItem('¿Cómo creo una clase?', 'Ve a la pestaña Clases y pulsa el botón "+" en la esquina superior derecha.'),
            _buildFAQItem('¿Cómo cobro mis clases?', 'Configura tu cuenta bancaria en la sección Finanzas para recibir tus pagos.'),
            _buildFAQItem('¿Qué diferencia hay entre Alumno/a y Profesor/a?', 'El perfil de Alumno/a está diseñado para buscar, reservar y disfrutar clases. El perfil de Profesor/a te entrega herramientas profesionales para gestionar tu agenda, alumnos y finanzas.'),
            _buildFAQItem('¿Qué es "Mi Academia"?', 'Es un módulo diseñado para administradores de espacios que permite gestionar múltiples salas y coordinar con otros/as profesores/as.'),
            _buildFAQItem('¿Cómo creo una Sede?', 'Ve a Configuraciones > Mis Sedes y pulsa el botón "+" para agregar una nueva ubicación donde impartirás tus clases.'),
            
            const SizedBox(height: 32),
            const Text('Contacto Directo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildContactCard(context, Icons.email, 'Correo', 'hola@plads.cl')),
                const SizedBox(width: 12),
                Expanded(child: _buildContactCard(context, Icons.phone, 'WhatsApp', '+56 9 2985 2163')),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('Envíanos un Mensaje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Asunto',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Mensaje',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Describe tu problema o sugerencia...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensaje enviado. Te responderemos pronto.')));
                           Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Enviar Mensaje'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: Text('Versión 2.0.1 (Beta)', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.neonPurple, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox( // Ensures long phone numbers/emails don't overflow
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
