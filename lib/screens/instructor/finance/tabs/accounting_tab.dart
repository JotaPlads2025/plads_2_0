import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../models/transaction_model.dart';
import '../../../../models/academy_model.dart';
import '../../../../utils/currency_helper.dart';

class AccountingTab extends StatefulWidget {
  final String currentPlan;
  
  const AccountingTab({super.key, required this.currentPlan});

  @override
  State<AccountingTab> createState() => _AccountingTabState();
}

class _AccountingTabState extends State<AccountingTab> {
  String _selectedMonth = 'Octubre'; // Mock Filter
  final List<String> _months = ['Agosto', 'Septiembre', 'Octubre'];
  
  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false); 
    final user = authService.currentUser; // Get current user

    return FutureBuilder<AcademyModel?>(
       // Fetch Academy to get Country (assuming 1 academy per instructor for now)
       future: user != null ? firestore.getInstructorAcademy(user.uid) : Future.value(null),
       builder: (context, academySnapshot) {
         if (academySnapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
         }

         final academy = academySnapshot.data;
         final countryCode = academy?.country ?? 'CL';

         return StreamBuilder<List<Transaction>>(
           stream: firestore.getTransactions(),
           builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactions = snapshot.data ?? [];
            
            // Calculate totals
            final planName = widget.currentPlan;
            
            // Commission Logic
            double commissionRate = 0.0;
            double fixedMonthlyFee = 0.0;
            
            if (planName == 'Pro') {
              commissionRate = 0.029; // 2.9%
              fixedMonthlyFee = 29990.0;
            } else if (planName == 'Básico') {
              commissionRate = 0.05; // 5%
              fixedMonthlyFee = 14990.0;
            } else {
              // Commission Only (Default or assume 'Comisión')
              commissionRate = 0.10; // 10%
              fixedMonthlyFee = 0.0;
            }

            double totalRevenue = 0.0;
            double appPaymentsTotal = 0.0;
            double manualPaymentsTotal = 0.0;

            for (var t in transactions) {
              totalRevenue += t.amount;
              if (t.method == PaymentMethod.app) {
                appPaymentsTotal += t.amount;
              } else {
                manualPaymentsTotal += t.amount;
              }
            }
                
            final variableCommission = appPaymentsTotal * commissionRate;
            final owedToPlads = variableCommission + fixedMonthlyFee; 

            // Split for Analysis
            int manualPaymentsCount = 0;
            int appPaymentsCount = 0;
            
            for (var t in transactions) {
              if (t.method == PaymentMethod.app) {
                appPaymentsCount++;
              } else {
                manualPaymentsCount++;
              }
            }

            final totalCount = transactions.isEmpty ? 1 : transactions.length;
            
            final appPct = '${(appPaymentsCount / totalCount * 100).toStringAsFixed(0)}%';
            final manualPct = '${(manualPaymentsCount / totalCount * 100).toStringAsFixed(0)}%';


            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Month Filter
                _buildMonthFilter(theme),
                const SizedBox(height: 16),
                
                // 2. Summary Cards
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard(theme, 'Ingresos Totales', totalRevenue, Icons.attach_money, Colors.green, countryCode)), 
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard(theme, 'Comisión Plads + Plan', -owedToPlads, Icons.money_off, Colors.redAccent, countryCode)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildOwedCard(theme, owedToPlads, countryCode),
                
                const SizedBox(height: 24),
                
                // 3. Transactions List
                const Text('Movimientos Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTransactionsList(theme, transactions, countryCode),
                
                const SizedBox(height: 24),
                
                // 4. Analysis
                _buildAnalysisCard(theme, appPct, manualPct),
              ],
            );
          }
        );
      }
    );
  }
  
  Widget _buildMonthFilter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          isExpanded: true,
          icon: const Icon(Icons.calendar_today, size: 18),
          items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) => setState(() => _selectedMonth = val!),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, String title, double amount, IconData icon, Color color, String countryCode) {
    // Adaptive text color for Light/Dark mode
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), 
          const SizedBox(height: 4),
          Text(
            CurrencyHelper.format(amount.abs(), countryCode), 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: textColor
            )
          ),
        ],
      ),
    );
  }
  
  Widget _buildOwedCard(ThemeData theme, double amount, String countryCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total a pagar a Plads', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 4),
              Text('Plan: ${widget.currentPlan}', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(
            CurrencyHelper.format(amount, countryCode),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.neonGreen)
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme, List<Transaction> transactions, String countryCode) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No hay movimientos aún.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        // Define colors and icons based on payment method
        Color methodColor;
        IconData methodIcon;
        
        switch (t.method) {
          case PaymentMethod.app:
            methodColor = AppColors.neonPurple;
            methodIcon = Icons.phone_android;
            break;
          case PaymentMethod.cash:
            methodColor = Colors.green;
            methodIcon = Icons.money;
            break;
          case PaymentMethod.transfer:
            methodColor = Colors.blue;
            methodIcon = Icons.account_balance;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(methodIcon, color: methodColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      t.item, 
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                       overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${CurrencyHelper.format(t.amount, countryCode)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text(DateFormat('dd MMM - HH:mm').format(t.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnalysisCard(ThemeData theme, String appPct, String manualPct) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: const [
               Text('Desglose de Ingresos', style: TextStyle(fontWeight: FontWeight.bold)),
               Icon(Icons.pie_chart, color: Colors.grey),
             ],
           ),
           const SizedBox(height: 16),
           Row(
             children: [
               Expanded(child: _buildLegendItem('App Plads', Colors.purple, appPct)),
               Expanded(child: _buildLegendItem('Manual', Colors.blue, manualPct)),
             ],
           ),
           const SizedBox(height: 12),
           Stack(
             children: [
               Container(
                 height: 10, 
                 decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(5))
               ),
               FractionallySizedBox(
                 widthFactor: 0.65, // Static for now, could be dynamic
                 child: Container(
                   height: 10, 
                   decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(5))
                 ),
               ),
             ],
           )
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, String pct) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(pct, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
