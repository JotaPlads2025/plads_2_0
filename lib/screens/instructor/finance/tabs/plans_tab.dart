import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/neon_widgets.dart';

class PlansTab extends StatefulWidget {
  final String currentPlan;
  final ValueChanged<String> onPlanChanged;

  const PlansTab({
    super.key,
    required this.currentPlan,
    required this.onPlanChanged,
  });

  @override
  State<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<PlansTab> {
  // Calculator State (Simulated)
  double _ticketPrice = 4000; 
  double _monthlyStudents = 70;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate totals for simulator
    final totalRevenue = _ticketPrice * _monthlyStudents;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          const Text(
            'Elige el Plan Perfecto para Ti',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Escala tu negocio con nuestras herramientas. Cambia cuando quieras.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Plans Carousel (Horizontal Scroll)
          SizedBox(
            height: 600, // INCREASED HEIGHT to fix button cutoff
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPlanCard(
                  context,
                  title: 'Comisión',
                  price: '10%',
                  period: 'por transacción',
                  description: 'Ideal para comenzar (Sofía). Ventas < \$300.000',
                  features: {
                    'Agendamiento Ilimitado': true,
                    'Gestión de clases': true,
                    'Perfil público': true,
                    'Soporte estándar': true,
                    'Verificación (Blue Tick)': false,
                    'Campañas Email': false,
                    'Asistente IA': false,
                  },
                  isCurrent: widget.currentPlan == 'commission', // Fixed case sensitive check
                  color: Colors.blueAccent,
                  onSelect: () => _confirmPlanChange('commission'),
                ),
                _buildPlanCard(
                  context,
                  title: 'Básico',
                  price: '\$14.990',
                  period: 'mes + 5% comisión',
                  description: 'Para consolidar ingresos (Marcos). Ventas > \$300.000',
                  features: {
                    'Agendamiento Ilimitado': true,
                    'Gestión de clases': true,
                    'Perfil público': true,
                    'Verificación (Blue Tick)': true, // Key feature
                    'Soporte Prioritario': true,
                    'Campañas Email': true,
                    'Asistente IA': false,
                  },
                  isCurrent: widget.currentPlan == 'basic',
                  color: AppColors.neonPurple,
                  onSelect: () => _confirmPlanChange('basic'),
                ),
                _buildPlanCard(
                  context,
                  title: 'Pro',
                  price: '\$29.990',
                  period: 'mes + 2.9% comisión',
                  description: 'Para academias y alto volumen (Laura). Ventas > \$715.000',
                  features: {
                    'Todo lo del Plan Básico': true,
                    'Comisión reducida (2.9%)': true,
                    'Asistente IA Marketing': true, // Key feature
                    'Mi Academia (Multi-sede)': true,
                    'Analítica Avanzada': true,
                    'Posicionamiento Destacado': true,
                  },
                  // Use 'pro' lowercase to match user model
                  isCurrent: widget.currentPlan == 'pro',
                  isFeatured: true, 
                  color: AppColors.neonGreen,
                  onSelect: () => _confirmPlanChange('pro'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),

          // Calculator Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   children: const [
                     Icon(Icons.calculate, color: AppColors.neonGreen),
                     SizedBox(width: 12),
                     Expanded(
                       child: Text(
                         'Simulador de Costos',
                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text(
                   'Calcula cuánto pagarías a Plads según tu volumen de clases.',
                   style: TextStyle(color: Colors.grey.shade500),
                 ),
                 const SizedBox(height: 32),

                 // Sliders
                 _buildSlider(
                   label: 'Precio por Clase',
                   value: _ticketPrice,
                   min: 1000,
                   max: 20000,
                   divisions: 19,
                   color: AppColors.neonPurple,
                   onChanged: (val) => setState(() => _ticketPrice = val),
                 ),
                 const SizedBox(height: 24),
                 _buildSlider(
                   label: 'Alumnos al Mes',
                   value: _monthlyStudents,
                   min: 0,
                   max: 500,
                   divisions: 100,
                   color: AppColors.neonGreen,
                   onChanged: (val) => setState(() => _monthlyStudents = val),
                 ),

                 const SizedBox(height: 20),
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Tus Ingresos Brutos:', style: TextStyle(color: Colors.grey)),
                       Text('\$${totalRevenue.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                     ],
                   ),
                 ),

                 const SizedBox(height: 40),
                 const Divider(),
                 const SizedBox(height: 20),
                 
                 // Results Comparison
                 const Text('Comparativa: ¿Cuánto le pagas a Plads?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 // Commission Plan: 10%
                 _buildCostResult('Plan Comisión', totalRevenue * 0.10, totalRevenue),
                 // Basic Plan: Fixed + 5%
                 _buildCostResult('Plan Básico', 14990 + (totalRevenue * 0.05), totalRevenue),
                 // Pro Plan: Fixed + 2.9%
                 _buildCostResult('Plan Pro', 29990 + (totalRevenue * 0.029), totalRevenue),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmPlanChange(String newPlan) {
    // Calculate effective date (Next Month 1st)
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final formattedDate = DateFormat('dd MMMM', 'es_ES').format(nextMonth);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cambio de Plan'),
        content: Text(
          'Tu plan cambiará a "$newPlan".\n\nEste cambio se hará efectivo en el próximo ciclo de facturación ($formattedDate).',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPlanChanged(newPlan);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen, foregroundColor: Colors.black),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  double _calculateCost(String plan, double revenue) {
     switch (plan) {
      case 'commission': return revenue * 0.10;
      case 'basic': return 14990 + (revenue * 0.05);
      case 'pro': return 29990 + (revenue * 0.029);
      default: return 0;
    }
  }

  Widget _buildSlider({required String label, required double value, required double min, required double max, int? divisions, required Color color, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
            Text(
              label.contains('Precio') ? '\$${value.toInt()}' : '${value.toInt()}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCostResult(String planName, double costToPlads, double totalRevenue) {
    // Determine if this is the cheapest option
    final commCost = _calculateCost('commission', totalRevenue);
    final basicCost = _calculateCost('basic', totalRevenue);
    final proCost = _calculateCost('pro', totalRevenue);
    
    final minCost = [commCost, basicCost, proCost].reduce((curr, next) => curr < next ? curr : next);
    final isBest = (costToPlads - minCost).abs() < 1; // Tolerance for float comparison

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBest ? AppColors.neonGreen.withOpacity(0.1) : Colors.transparent,
        border: isBest ? Border.all(color: AppColors.neonGreen) : Border(bottom: BorderSide(color: Colors.grey.shade800)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(planName, style: TextStyle(fontWeight: isBest? FontWeight.bold : FontWeight.normal)),
                  if (isBest) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.neonGreen, borderRadius: BorderRadius.circular(4)),
                      child: const Text('MEJOR PRECIO', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
              Text('\$${costToPlads.toInt()}', style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: isBest ? AppColors.neonGreen : Colors.white70,
              )),
            ],
          ),
          if (isBest)
            Padding(
               padding: const EdgeInsets.only(top: 4),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                    Text(
                      'Te ahorras \$${(commCost - costToPlads).toInt()} vs Comisión',
                      style: const TextStyle(color: AppColors.neonGreen, fontSize: 11)
                    )
                 ],
               ),
            )
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, {
    required String title,
    required String price,
    required String period,
    required String description,
    required Map<String, bool> features,
    required bool isCurrent,
    bool isFeatured = false,
    required Color color,
    required VoidCallback onSelect,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isFeatured 
            ? Border.all(color: color, width: 2) 
            : Border.all(color: Colors.grey.shade800),
        boxShadow: isFeatured ? [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))
        ] : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use min size, but parent sends Constraints
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(period, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Text(description, style: TextStyle(color: Colors.grey.shade500, height: 1.4)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Expanded( // Fill available space
            child: SingleChildScrollView( // Allow scrolling if features list is huge
              child: Column(
                 children: [
                    ...features.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            entry.value ? Icons.check_circle : Icons.cancel, 
                            color: entry.value ? Colors.greenAccent : Colors.grey.shade700, 
                            size: 20
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            entry.key, 
                            style: TextStyle(
                              fontSize: 13,
                              color: entry.value ? theme.textTheme.bodyMedium?.color : Colors.grey.shade600
                            )
                          )),
                        ],
                      ),
                    )),
                 ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              text: isCurrent ? 'Plan Actual' : 'Seleccionar',
              onPressed: isCurrent ? null : onSelect,
              color: isCurrent ? Colors.grey : color,
            ),
          )
        ],
      ),
    );
  }
}
