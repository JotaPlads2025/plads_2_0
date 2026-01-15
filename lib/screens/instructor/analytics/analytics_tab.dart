import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/class_performance_table.dart';
import '../../../../widgets/neon_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../repositories/class_repository.dart';
import '../../../../models/class_model.dart';
import 'package:intl/intl.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _selectedRange = '6 Meses';
  bool _isLoading = true;
  
  // Metrics Data
  double _totalRevenue = 0;
  double _attendanceRate = 0;
  int _newStudents = 0; // Requires User creation date tracking, mocking for now or inferring from new attendees
  List<Map<String, dynamic>> _topClassesData = [];
  List<double> _monthlyRevenue = [0,0,0,0,0,0]; // Last 6 months

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    final repo = ClassRepository();
    
    try {
      // 1. Fetch all classes
      final classes = await repo.getInstructorClasses(user.uid);
      
      // 2. Initialize counters
      double totalRev = 0;
      double totalCapacity = 0;
      double totalAttendance = 0;
      Map<String, double> classRevenueMap = {};
      Map<String, double> classAttendanceMap = {};
      
      // Monthly buckets (Current month is index 5, previous is 4, etc.)
      List<double> monthlyRev = List.filled(6, 0.0);
      final now = DateTime.now();

      for (var cls in classes) {
        // A. Revenue (Based on enrolled students * price) - Assumption: All enrolled paid
        // Improve this later with specific Transaction logic if available.
        final revenue = cls.price * cls.attendeeIds.length;
        totalRev += revenue;
        
        // B. Attendance Rate (Based on VERIFIED attendance)
        final verifiedCount = cls.attendance.length;
        totalAttendance += verifiedCount;
        totalCapacity += cls.capacity > 0 ? cls.capacity : 1; // Avoid div/0
        
        // C. Top Classes Data
        classRevenueMap[cls.title] = (classRevenueMap[cls.title] ?? 0) + revenue;
        // Weighted average for attendance? Or just total verified count per class name?
        // Let's store total verified and total capacity per class name to average later
        // Simplified: Just use latest or average of all instances.
        
        // D. Monthly Buckets
        final monthDiff = (now.year - cls.date.year) * 12 + now.month - cls.date.month;
        if (monthDiff >= 0 && monthDiff < 6) {
           // index 5 is current month (diff 0), index 0 is 6 months ago (diff 5)
           monthlyRev[5 - monthDiff] += revenue; 
        }
      }

      // 3. Process Top Classes (Grouping by Name)
      // We need a more robust grouping, but for MVP let's show individual class instances performance or aggregated?
      // Aggregated by name seems better for "Top Classes".
      final Map<String, Map<String, double>> aggregatedClasses = {}; 
      // { 'Bachata': { 'rev': 5000, 'att': 10, 'cap': 20 } }
      
      for (var cls in classes) {
         if (!aggregatedClasses.containsKey(cls.title)) {
           aggregatedClasses[cls.title] = {'rev': 0, 'att': 0, 'cap': 0};
         }
         aggregatedClasses[cls.title]!['rev'] = aggregatedClasses[cls.title]!['rev']! + (cls.price * cls.attendeeIds.length);
         aggregatedClasses[cls.title]!['att'] = aggregatedClasses[cls.title]!['att']! + cls.attendance.length;
         aggregatedClasses[cls.title]!['cap'] = aggregatedClasses[cls.title]!['cap']! + cls.capacity;
      }

      final List<Map<String, dynamic>> sortedClasses = aggregatedClasses.entries.map((e) {
         final att = e.value['att']!;
         final cap = e.value['cap']!;
         final rate = cap > 0 ? att / cap : 0.0;
         return {
           'name': e.key,
           'attendanceRate': rate,
           'revenue': e.value['rev']
         };
      }).toList();
      
      // Sort by Revenue descending
      sortedClasses.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      setState(() {
        _totalRevenue = totalRev;
        _attendanceRate = totalCapacity > 0 ? (totalAttendance / totalCapacity) : 0;
        _topClassesData = sortedClasses.take(5).toList();
        _monthlyRevenue = monthlyRev;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading metrics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // For MVP/Demo: Always allowed access
    
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resumen Financiero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedRange,
                      underline: const SizedBox(),
                      style: TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold),
                      icon: Icon(Icons.keyboard_arrow_down, color: AppColors.neonPurple),
                      items: ['6 Meses'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), // Locked to 6 months for MVP logic
                      onChanged: (v) {},
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // METRICS SECTION
                if (isWide)
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Ingresos Totales', currencyFormat.format(_totalRevenue), Icons.attach_money, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Asistencia Prom.', '${(_attendanceRate * 100).toInt()}%', Icons.groups, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Clases Realizadas', '${_topClassesData.length}', Icons.class_, Colors.purple)), // Replaced New Students
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Retención', 'Calculating...', Icons.loop, Colors.orange)), // Placeholder
                    ],
                  )
                else ...[
                   Row(
                    children: [
                      Expanded(child: _buildMetricCard('Ingresos Totales', currencyFormat.format(_totalRevenue), Icons.attach_money, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Asistencia Prom.', '${(_attendanceRate * 100).toInt()}%', Icons.groups, Colors.blue)),
                    ],
                  ),
                   const SizedBox(height: 12),
                ],
                
                const SizedBox(height: 24),
                
                // MAIN CONTENT SECTION
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: Revenue Chart
                      Expanded(
                        flex: 2,
                        child: _buildRevenueChartContainer(context),
                      ),
                      const SizedBox(width: 24),
                      // RIGHT: Class Performance Table
                      Expanded(
                        flex: 1,
                        child: ClassPerformanceTable(classData: _topClassesData),
                      ),
                    ],
                  )
                else ...[
                  // Mobile Layout
                  _buildRevenueChartContainer(context),
                  const SizedBox(height: 24),
                  ClassPerformanceTable(classData: _topClassesData),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildRevenueChartContainer(BuildContext context) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: AppColors.neonPurple.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tendencia de Ingresos (Últimos 6 meses)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: RevenueChart(
                  monthlyRevenue: _monthlyRevenue,
                  isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
