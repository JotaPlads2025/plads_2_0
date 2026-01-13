import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../../theme/app_theme.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../models/student_model.dart';
import '../../../../models/transaction_model.dart' as tm;
import '../../../../models/class_model.dart';
import '../../../../models/academy_model.dart';
import '../../../../utils/currency_helper.dart';
import '../profile/profile_screen.dart'; 

class DashboardTab extends StatefulWidget {
  final String userName;
  const DashboardTab({super.key, this.userName = 'Instructor'});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // State for expandables
  bool _isChartExpanded = true;
  bool _isClassesExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return FutureBuilder<AcademyModel?>(
      future: user != null ? firestore.getInstructorAcademy(user.uid) : Future.value(null),
      builder: (context, academySnapshot) {
        final academy = academySnapshot.data;
        final countryCode = academy?.country ?? 'CL';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: isWide 
                // --- DESKTOP LAYOUT (2 Columns) ---
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN (Main Content: Header + KPIs)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           _buildHeader(context, user),
                           const SizedBox(height: 24),
                           _buildKpisAndCharts(context, firestore, countryCode, isWide: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // RIGHT COLUMN (Side Panel: Upcoming Classes)
                      Expanded(
                        flex: 2,
                        child: _buildClassesPanel(context, firestore, isWide: true),
                      ),
                    ],
                  )
                // --- MOBILE LAYOUT (1 Column) ---
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, user),
                      const SizedBox(height: 24),
                      _buildKpisAndCharts(context, firestore, countryCode, isWide: false),
                      const SizedBox(height: 32),
                      _buildClassesPanel(context, firestore, isWide: false),
                      const SizedBox(height: 80), 
                    ],
                  ),
            );
          }
        );
      }
    );
  }

  // --- WIDGET EXTRACTION FOR READABILITY ---

  Widget _buildHeader(BuildContext context, dynamic user) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Hola, ${user?.displayName ?? 'Instructor'}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
             const Text('Aquí tienes el resumen de tu academia', style: TextStyle(color: Colors.grey)),
          ],
        ),
          GestureDetector(
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.neonGreen,
            backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty) 
                ? NetworkImage(user.photoURL!) 
                : null,
            child: (user?.photoURL != null && user!.photoURL!.isNotEmpty) 
                ? null 
                : Text(widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'I', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
         ),
      ],
    );
  }

  Widget _buildKpisAndCharts(BuildContext context, FirestoreService firestore, String countryCode, {required bool isWide}) {
    return StreamBuilder<List<tm.Transaction>>(
      stream: firestore.getTransactions(),
      builder: (context, snapshotTrans) {
        final transactions = snapshotTrans.data ?? [];
        final totalRevenue = transactions.fold(0.0, (sum, t) => sum + t.amount);
        
        return StreamBuilder<List<ClassModel>>(
          stream: firestore.getInstructorClasses(firestore.currentUser?.uid ?? ''),
          builder: (context, snapshotClasses) {
            final classes = snapshotClasses.data ?? [];
            final activeClassesCount = classes.where((c) => c.date.isAfter(DateTime.now())).length;
            final uniqueStudentIds = transactions.map((t) => t.studentId).toSet();
            final totalStudents = uniqueStudentIds.length;

            final List<Map<String, dynamic>> kpiData = [
                {
                  'title': 'Ingresos Totales',
                  'value': CurrencyHelper.format(totalRevenue, countryCode),
                  'icon': Icons.attach_money,
                  'color': AppColors.neonGreen,
                  'trend': 'Real', 
                },
                {
                  'title': 'Alumnos Activos',
                  'value': totalStudents.toString(),
                  'icon': Icons.people,
                  'color': AppColors.neonPurple,
                  'trend': 'Total',
                },
                {
                  'title': 'Clases Activas',
                  'value': activeClassesCount.toString(),
                  'icon': Icons.fitness_center,
                  'color': Colors.orangeAccent,
                  'trend': 'Futuras',
                },
            ];

            // KPIs Grid
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 2, // 3 columns on wide screen, 2 on mobile
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.8 : 1.3, // Shorter cards on desktop
              ),
              itemCount: kpiData.length,
              itemBuilder: (context, index) => _buildKpiCard(context, kpiData[index]),
            );
          }
        );
      }
    );
  }

  Widget _buildClassesPanel(BuildContext context, FirestoreService firestore, {required bool isWide}) {
    final theme = Theme.of(context);
    return StreamBuilder<List<ClassModel>>(
      stream: firestore.getInstructorClasses(firestore.currentUser?.uid ?? ''),
      builder: (context, snapshotClasses) {
        final classes = snapshotClasses.data ?? [];
        final upcomingClasses = classes.where((c) => c.date.isAfter(DateTime.now())).take(isWide ? 10 : 3).toList();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: isWide ? null : () => setState(() => _isClassesExpanded = !_isClassesExpanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Próximas Clases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     if (!isWide) Icon(
                       _isClassesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                       color: Colors.grey,
                     ),
                  ],
                ),
              ),
              if (isWide || _isClassesExpanded) ...[
                const SizedBox(height: 16),
                if (upcomingClasses.isEmpty)
                  const Text("No tienes clases programadas.", style: TextStyle(color: Colors.grey))
                else
                  ...upcomingClasses.map((c) {
                    final color = [Colors.blueAccent, Colors.orangeAccent, AppColors.neonPurple][classes.indexOf(c) % 3];
                    return _buildClassTile(
                      title: c.title, 
                      time: '${DateFormat('dd MMM').format(c.date)} ${c.startTime}', 
                      students: c.attendeeIds.length + c.manualAttendees.length, 
                      max: c.capacity, 
                      color: color
                    );
                  }).toList()
              ]
            ],
          ),
        );
      }
    );
  }


  Widget _buildKpiCard(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: (data['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                 child: Icon(data['icon'] as IconData, color: data['color'] as Color, size: 20),
               ),
               Text(data['trend'] as String, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['value'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              Text(data['title'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildClassTile({required String title, required String time, required int students, required int max, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.class_, color: color, size: 20)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('$students/$max', style: TextStyle(fontWeight: FontWeight.bold, color: students >= max ? Colors.red : Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}
