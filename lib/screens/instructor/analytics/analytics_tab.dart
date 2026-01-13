import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/class_performance_table.dart';
import '../../../../widgets/neon_widgets.dart'; // Ensure correct path
import 'package:provider/provider.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../models/transaction_model.dart';
import '../finance/finance_screen.dart'; // For upgrade

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _selectedRange = '6 Meses';
  
  // Simulated Plan Status (In real app, fetch from User Model)
  // For demo: Show LOCKED screen if commission based, UNLOCKED if Pro.
  // We can simulate this with a toggle or just default to LOCKED to force upgrade flow demo.
  // User asked for "Basic" and "Pro" only.
  // Let's assume for now the user is "Commission" (default) to show the upsell, 
  // or add a way to toggle it.
  // Let's check a shared pref or just fetch user. For MVP, let's allow viewing if user has flag.
  bool _hasProPlan = true; // Set to true for DEVELOPMENT/DEMO as requested to see charts.
  
  @override
  Widget build(BuildContext context) {
    if (!_hasProPlan) {
      return _buildLockedView();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.download))
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

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
                      items: ['Mes Actual', '3 Meses', '6 Meses', 'Anual'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedRange = v!),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // METRICS SECTION
                if (isWide)
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Ingresos Totales', '\$1.2M', Icons.attach_money, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Asistencia Prom.', '85%', Icons.groups, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Nuevos Alumnos', '+12', Icons.person_add, Colors.purple)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Retención', '92%', Icons.loop, Colors.orange)),
                    ],
                  )
                else ...[
                   Row(
                    children: [
                      Expanded(child: _buildMetricCard('Ingresos Totales', '\$1.2M', Icons.attach_money, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Asistencia Prom.', '85%', Icons.groups, Colors.blue)),
                    ],
                  ),
                   const SizedBox(height: 12),
                   Row(
                    children: [
                      Expanded(child: _buildMetricCard('Nuevos Alumnos', '+12', Icons.person_add, Colors.purple)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Retención', '92%', Icons.loop, Colors.orange)),
                    ],
                  ),
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
                        child: Container(
                          height: 400, // Taller on desktop
                          padding: const EdgeInsets.all(16), // Inner padding
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
                              const Text('Tendencia de Ingresos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 20),
                              Expanded(
                                child: RevenueChart(
                                   monthlyRevenue: const [150000, 180000, 165000, 210000, 250000, 290000],
                                   isDark: Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // RIGHT: Class Performance Table
                      const Expanded(
                        flex: 1,
                        child: ClassPerformanceTable(classData: [
                           {'name': 'Bachata Sensual', 'attendanceRate': 0.95, 'revenue': 450000},
                           {'name': 'Salsa Cubana', 'attendanceRate': 0.82, 'revenue': 320000},
                           {'name': 'Kizomba', 'attendanceRate': 0.60, 'revenue': 150000},
                           {'name': 'Lady Style', 'attendanceRate': 0.45, 'revenue': 80000},
                        ]),
                      ),
                    ],
                  )
                else ...[
                  // Mobile Layout
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: AppColors.neonPurple.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                      ]
                    ),
                    child: RevenueChart(
                       monthlyRevenue: const [150000, 180000, 165000, 210000, 250000, 290000],
                       isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const ClassPerformanceTable(classData: [
                     {'name': 'Bachata Sensual', 'attendanceRate': 0.95, 'revenue': 450000},
                     {'name': 'Salsa Cubana', 'attendanceRate': 0.82, 'revenue': 320000},
                     {'name': 'Kizomba', 'attendanceRate': 0.60, 'revenue': 150000},
                     {'name': 'Lady Style', 'attendanceRate': 0.45, 'revenue': 80000},
                  ]),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        }
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
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Opacity(opacity: 0.5, child: Icon(Icons.bar_chart, size: 80, color: Colors.grey)),
             const SizedBox(height: 24),
             const Text('Estadísticas Pro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             const Text(
               'Analiza tu crecimiento, ingresos y retención con gráficos detallados. Disponible en planes Básico y Pro.',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.grey),
             ),
             const SizedBox(height: 32),
             NeonButton(
               text: 'Ver Planes', 
               color: AppColors.neonPurple,
               onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen()));
               }
             )
          ],
        ),
      ),
    );
  }
}
