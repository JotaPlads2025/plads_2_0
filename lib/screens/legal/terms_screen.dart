import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos de Uso de Plads',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Última actualización: 30 de Diciembre, 2025', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Introducción',
              content: 'Bienvenido a Plads. Al acceder o utilizar nuestra aplicación móvil, aceptas estar legalmente obligado por estos términos. Plads actúa como una plataforma tecnológica que conecta a Instructores de actividades físicas con Estudiantes.',
            ),
            _buildSection(
              title: '2. Rol de Plads',
              content: 'Plads no es un gimnasio ni una academia de baile. Somos un intermediario tecnológico que facilita la gestión, reserva y pago de clases. La relación contractual por los servicios de enseñanza es directa entre el Instructor y el Estudiante.',
            ),
            _buildSection(
              title: '3. Pagos y Tarifas',
              content: 'Los precios de las clases son establecidos libremente por los Instructores. Plads puede cobrar una tarifa de servicio o comisión por el uso de la plataforma, la cual será claramente detallada antes de cualquier transacción.',
            ),
            _buildSection(
              title: '4. Política de Cancelación y Reembolsos',
              content: 'Cada Instructor define sus propias políticas de cancelación. Los Estudiantes deben revisar estas reglas antes de reservar. Plads no se hace responsable por reembolsos de clases no asistidas, salvo fallas técnicas comprobables de la plataforma.',
            ),
            _buildSection(
              title: '5. Responsabilidad y Seguridad Física',
              content: 'El usuario reconoce que la práctica de baile y actividades físicas conlleva riesgos inherentes de lesiones. Al usar Plads, exoneras a la plataforma y a sus desarrolladores de cualquier responsabilidad por lesiones físicas ocurridas durante las clases. Es responsabilidad del Estudiante consultar con un médico antes de iniciar actividad física.',
            ),
            _buildSection(
              title: '6. Comportamiento del Usuario',
              content: 'Queda prohibido el uso de la plataforma para acoso, discriminación, actividades ilegales o spam. Plads se reserva el derecho de suspender o eliminar cuentas que violen estas normas de convivencia.',
            ),
            _buildSection(
              title: '7. Estándares de Calidad para Instructores',
              content: 'Para garantizar la calidad del servicio, los Instructores deben mantener una calificación promedio mínima de 3.0 estrellas, basada en las reseñas de los Estudiantes. Plads se reserva el derecho de suspender o desactivar temporalmente las cuentas de Instructores que no cumplan con este estándar de calidad de forma reiterada.',
            ),
            _buildSection(
              title: '8. Propiedad Intelectual',
              content: 'Todo el diseño, marca, código y contenido de la aplicación Plads es propiedad exclusiva de Plads. El contenido subido por los Instructores (fotos, descripciones) sigue siendo de su propiedad, pero otorgan una licencia a Plads para mostrarlo en la plataforma.',
            ),
             _buildSection(
              title: '9. Modificaciones',
              content: 'Nos reservamos el derecho de modificar estos términos en cualquier momento. Las modificaciones entrarán en vigor inmediatamente después de su publicación en la App.',
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
