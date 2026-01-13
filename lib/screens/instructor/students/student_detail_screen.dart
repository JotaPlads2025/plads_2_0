import 'package:flutter/material.dart';
import '../../../../models/student_model.dart'; // Unified Model
import '../../../../models/access_grant_model.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/firestore_service.dart';
import '../../../../models/class_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil del Alumno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(context, student),
            const SizedBox(height: 30),
            _buildPlanCard(context, student),
            const SizedBox(height: 30),
            _buildHistory(context, student),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentModel s) {
    return Column(
      children: [
        Hero(
          tag: 'avatar_${s.id}',
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: s.avatarColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: s.avatarColor, width: 2),
              boxShadow: [
                BoxShadow(blurRadius: 20, color: s.avatarColor.withOpacity(0.3))
              ],
            ),
            child: Center(
              child: Text(
                s.initials,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: s.avatarColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          s.status == StudentStatus.activePlan ? 'Abonado Activo' : 
          (s.status == StudentStatus.dropIn ? 'Alumno Frecuente' : 'Inactivo'),
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(Icons.chat, 'WhatsApp', const Color(0xFF25D366)),
            const SizedBox(width: 16),
            _buildActionButton(Icons.phone, 'Llamar', Colors.lightBlue),
            const SizedBox(width: 16),
            _buildActionButton(Icons.email, 'Correo', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, StudentModel s) {
    if (s.activeSubscriptions.isEmpty) {
      if (s.status == StudentStatus.activePlan) {
        return const Center(child: Text("Estado 'Activo' pero sin planes visibles."));
      }
      return const SizedBox.shrink();
    }

    return Column(
      children: s.activeSubscriptions.map((grant) {
        // Determine colors/progress
        bool isPack = grant.type == AccessGrantType.pack;
        int remaining = grant.remainingClasses ?? 0;
        int total = grant.initialClasses ?? (remaining > 0 ? remaining : 1); // Fallback
        double progress = isPack ? (remaining / total) : 0.8; 

        // Check expiry for subscriptions
        int daysLeft = 0;
        if (grant.expiryDate != null) {
           daysLeft = grant.expiryDate!.difference(DateTime.now()).inDays;
           if (!isPack && daysLeft < 0) return const SizedBox.shrink(); // Hide expired?
        }

        return Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPack 
                  ? [const Color(0xFF320b86), const Color(0xFF9a0bde)] // Purple for Packs
                  : [Colors.blue.shade800, Colors.teal.shade700], // Blue/Teal for Monthly
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(grant.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Icon(isPack ? Icons.confirmation_number : Icons.calendar_today, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 10),
              // Chips for Scope
              Wrap(
                spacing: 8,
                children: [
                   if (grant.discipline != 'All') _buildTag(grant.discipline),
                   if (grant.level != 'All') _buildTag(grant.level),
                ],
              ),
              const SizedBox(height: 16),
              if (isPack) ...[
                Text('$remaining clases disponibles', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('en tu pack', style: TextStyle(color: Colors.white70)),
              ] else ...[
                 Text(daysLeft > 0 ? '$daysLeft días restantes' : 'Vence hoy', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                 const Text('de tu plan mensual', style: TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: isPack ? progress : 1.0, // Full bar for monthly or calculate time progress?
                backgroundColor: Colors.black26,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonGreen),
              ),
              const SizedBox(height: 8),
              if (grant.expiryDate != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                     Text('Vence: ${DateFormat('d MMM', 'es_ES').format(grant.expiryDate!)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _buildHistory(BuildContext context, StudentModel s) {
    // Real History Stream
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de Asistencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<List<ClassModel>>(
            stream: firestore.getStudentHistory(s.id),
            builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
               
               if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Si no aparece, crea el índice: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 10)),
                  );
               }

               final classes = snapshot.data ?? [];
               if (classes.isEmpty) {
                 return const Text('Aún no ha asistido a clases.', style: TextStyle(color: Colors.grey));
               }

               return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: classes.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final cls = classes[index];
                  // Date Format: "24 Oct"
                  final dayStr = DateFormat('d', 'es_ES').format(cls.date);
                  final monthStr = DateFormat('MMM', 'es_ES').format(cls.date);
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(monthStr.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(dayStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    title: Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(cls.startTime), 
                    trailing: Text(s.status == StudentStatus.activePlan ? '-1 clase' : '\$${cls.price.toStringAsFixed(0)}', 
                      style: TextStyle(
                        color: s.status == StudentStatus.activePlan ? Colors.redAccent : AppColors.neonGreen, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  );
                },
               );
            }
          ),
        ],
      ),
    );
  }
}
