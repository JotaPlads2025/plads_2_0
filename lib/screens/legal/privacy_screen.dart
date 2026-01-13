import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aviso de Privacidad',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Última actualización: 30 de Diciembre, 2025', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Información que Recopilamos',
              content: 'Podemos recopilar información personal como tu nombre, dirección de correo electrónico, número de teléfono y fotografía de perfil. Para Instructores, también recopilamos información de pago y detalles de la academia.',
            ),
            _buildSection(
              title: '2. Uso de la Información',
              content: 'Utilizamos tus datos para:\n• Gestionar tu cuenta y autenticación.\n• Procesar reservas y pagos.\n• Facilitar la comunicación entre Instructor y Estudiante.\n• Enviar notificaciones importantes sobre tus clases (cancelaciones, recordatorios).',
            ),
            _buildSection(
              title: '3. Compartir Información',
              content: 'Plads NO vende tus datos personales a terceros. Sin embargo, compartimos cierta información necesaria:\n• Instructores: Ven tu nombre y estado de asistencia para gestionar las clases.\n• Procesadores de Pago: Para ejecutar las transacciones financieras de forma segura.',
            ),
            _buildSection(
              title: '4. Seguridad de los Datos',
              content: 'Implementamos medidas de seguridad técnicas y organizativas para proteger tus datos. Utilizamos servicios en la nube de proveedores confiables (Google Cloud Platform) con encriptación estándar de la industria.',
            ),
            _buildSection(
              title: '5. Tus Derechos (ARCO)',
              content: 'Tienes derecho a Acceder, Rectificar, Cancelar u Oponerte al uso de tus datos personales. Puedes gestionar la mayoría de tus datos desde la sección "Perfil" de la aplicación o contactarnos a soporte@plads.cl para solicitudes específicas.',
            ),
            _buildSection(
              title: '6. Retención de Datos',
              content: 'Conservamos tu información mientras tu cuenta esté activa o sea necesario para cumplir con obligaciones legales y fiscales.',
            ),
            
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: AppColors.neonPurple,
                  foregroundColor: Colors.white
                ),
                child: const Text('Entendido'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.5, color: Colors.grey)),
        ],
      ),
    );
  }
}
