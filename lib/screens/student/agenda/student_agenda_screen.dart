import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/class_model.dart';

class StudentAgendaScreen extends StatelessWidget {
  const StudentAgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Mi Agenda', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          centerTitle: false,
          bottom: TabBar(
            indicatorColor: AppColors.neonPurple,
            labelColor: AppColors.neonPurple,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Próximas'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: StreamBuilder(
          stream: authService.user,
          initialData: authService.currentUserModel,
          builder: (context, userSnapshot) {
             final user = userSnapshot.data;
             if (user == null) return const Center(child: CircularProgressIndicator());

             return TabBarView(
              children: [
                _buildUpcomingList(context, user.id),
                _buildHistoryList(context, user.id), 
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildUpcomingList(BuildContext context, String userId) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<ClassModel>>(
      stream: firestoreService.getStudentClasses(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Error al cargar agenda', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Text('Si ves un error de "FAILED_PRECONDITION", falta crear un índice en Firebase.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        
        final classes = snapshot.data ?? [];
        
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 const Icon(Icons.event_busy, size: 60, color: Colors.grey),
                 const SizedBox(height: 16),
                 const Text('No tienes clases agendadas', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return _buildClassCard(
              context,
              classId: cls.id, // Pass ID
              userId: userId, // Pass User ID from parameter
              title: cls.title,
              instructor: cls.instructorName,
              time: '${DateFormat('d MMM', 'es_ES').format(cls.date)}, ${cls.startTime}',
              location: cls.location,
              status: 'Confirmada',
              statusColor: Colors.green,
              isUpcoming: true,
            );
          },
        );
      }
    );
  }

  Widget _buildHistoryList(BuildContext context, String userId) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<ClassModel>>(
      stream: firestoreService.getStudentClassHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
           return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        
        final classes = snapshot.data ?? [];
        
        if (classes.isEmpty) {
          return const Center(child: Text('No tienes clases pasadas.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            bool attended = cls.attendeeIds.contains(userId); // Simplified check, ideally check check-in status if available

            return _buildClassCard(
              context,
              classId: cls.id,
              userId: userId,
              title: cls.title,
              instructor: cls.instructorName,
              time: '${DateFormat('d MMM', 'es_ES').format(cls.date)}, ${cls.startTime}',
              location: cls.location,
              status: attended ? 'Asistió' : 'Ausente', 
              statusColor: attended ? Colors.grey : Colors.redAccent,
              isUpcoming: false,
            );
          },
        );
      }
    );
  }

  Widget _buildClassCard(BuildContext context, {
    required String classId,
    required String userId, // Add userId
    required String title,
    required String instructor,
    required String time,
    required String location,
    required String status,
    required Color statusColor,
    required bool isUpcoming,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              if (isUpcoming)
                const Icon(Icons.qr_code, color: AppColors.neonPurple), 
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(instructor, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(location, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                   _showQRModal(context, title, classId, userId);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neonPurple,
                  side: const BorderSide(color: AppColors.neonPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ver Entrada'),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _showQRModal(BuildContext context, String className, String classId, String userId) {
    final ticketId = '${classId}_$userId';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tu Entrada', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(className, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),
            QrImageView(
              data: ticketId,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 32),
            const Text('Presenta este código al instructor', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            Text('ID: ${ticketId.substring(0, 8)}...', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
