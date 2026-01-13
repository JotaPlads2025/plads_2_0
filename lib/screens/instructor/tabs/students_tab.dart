import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/student_model.dart';
import '../../../../models/access_grant_model.dart';
import '../students/student_detail_screen.dart';

import 'package:provider/provider.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/auth_service.dart';

import '../students/add_student_screen.dart';

class StudentsTab extends StatelessWidget {
  const StudentsTab({super.key});

  void _navigateToAddStudent(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // Access Firestore Service
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Inherit from parent
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Gestión de Alumnos', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: AppColors.neonGreen,
            labelColor: AppColors.neonGreen,
            unselectedLabelColor: Colors.grey,
            // isScrollable: true, // REMOVED to center tabs
            tabs: [
              Tab(text: 'Abonados (Plan)'),
              Tab(text: 'Clase a Clase'),
              Tab(text: 'Recuperación'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.person_add), 
              onPressed: () => _navigateToAddStudent(context)
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddStudent(context),
          backgroundColor: AppColors.neonGreen,
          child: const Icon(Icons.add, color: Colors.black),
        ),
        body: StreamBuilder<List<StudentModel>>(
          stream: firestore.getStudents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final currentInstructorId = Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
            final allStudents = snapshot.data ?? [];
            
            final subscribers = allStudents.where((s) => s.hasActivePlan).toList(); // Use updated getter

            final dropIns = allStudents.where((s) => s.status == StudentStatus.dropIn).toList();
            final recovery = allStudents.where((s) => s.status == StudentStatus.inactive).toList();

            return TabBarView(
              children: [
                _buildSubscribersList(subscribers, currentInstructorId),
                _buildDropInsList(dropIns),
                _buildRecoveryList(recovery),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildSubscribersList(List<StudentModel> students, String instructorId) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        
        // Summarize Subscriptions
        int totalClasses = 0;
        bool hasUnlimited = false;
        List<String> summaryParts = [];
        
        for (var grant in s.activeSubscriptions) {
           if (grant.isActive) {
             if (grant.type == AccessGrantType.subscription) {
               hasUnlimited = true;
               summaryParts.add(grant.name);
             } else {
               totalClasses += (grant.remainingClasses ?? 0);
               summaryParts.add('${grant.name} (${grant.remainingClasses})');
             }
           }
        }
        
        final subtitle = summaryParts.isEmpty ? 'Sin detalle' : summaryParts.join(', ');

        return Card(
          color: Theme.of(context).cardTheme.color,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: s))),
            leading: Hero(
              tag: 'avatar_${s.id}',
              child: CircleAvatar(
                backgroundColor: s.avatarColor.withOpacity(0.2),
                child: Text(s.initials, style: TextStyle(color: s.avatarColor, fontWeight: FontWeight.bold)),
              ),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasUnlimited ? 'Suscripción Activa' : 'Pack Activo', style: TextStyle(color: Colors.green.shade400)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ), 
            trailing: _buildCreditTrafficLight(hasUnlimited ? 999 : totalClasses),
          ),
        );
      },
    );
  }

  Widget _buildDropInsList(List<StudentModel> students) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return Card(
          color: Theme.of(context).cardTheme.color,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: s))),
             leading: Hero(
              tag: 'avatar_${s.id}',
              child: CircleAvatar(
                backgroundColor: s.avatarColor.withOpacity(0.2),
                child: Text(s.initials, style: TextStyle(color: s.avatarColor, fontWeight: FontWeight.bold)),
              ),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                 Icon(
                   s.paymentMethod == 'App Plads' ? Icons.phone_android : Icons.attach_money, 
                   size: 12, 
                   color: Colors.grey
                 ),
                 const SizedBox(width: 4),
                 Text(s.paymentMethod ?? 'Pago Manual', style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Última visita', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(_timeAgo(s.lastAttendance), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonGreen)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecoveryList(List<StudentModel> students) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return Card(
          color: Theme.of(context).cardTheme.color,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: s))),
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: const Icon(Icons.person_off, color: Colors.grey),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            subtitle: Text('Ausente hace ${_daysAgo(s.lastAttendance)} días', style: const TextStyle(color: Colors.redAccent)),
            trailing: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Recuperar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14).withOpacity(0.1),
                foregroundColor: const Color(0xFF39FF14),
                elevation: 0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditTrafficLight(int creditsRemaining) {
    Color color = Colors.green;
    if (creditsRemaining <= 1) color = Colors.red;
    else if (creditsRemaining <= 3) color = Colors.amber;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text('$creditsRemaining créditos', style: TextStyle(fontSize: 10, color: color)), 
      ],
    );
  }
  
  String _timeAgo(DateTime? date) {
    if (date == null) return 'Nuevo';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    return '${diff.inDays} días';
  }

  String _daysAgo(DateTime? date) {
    if (date == null) return '0';
    return DateTime.now().difference(date).inDays.toString();
  }
}
