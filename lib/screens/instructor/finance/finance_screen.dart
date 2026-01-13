import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'tabs/accounting_tab.dart';
import 'tabs/plans_tab.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  // Shared State
  String _currentPlan = 'Pro'; // Default Plan

  void _updatePlan(String newPlan) {
    setState(() {
      _currentPlan = newPlan;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan actualizado a: $newPlan'), backgroundColor: AppColors.neonGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using DefaultTabController is fine, but we need to rebuild children when state changes.
    // Since TabBarView keeps state, passing parameters might require unique keys or just passing them directly.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Finanzas'),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.neonGreen,
            labelColor: AppColors.neonGreen,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Contabilidad'),
              Tab(text: 'Mis Planes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AccountingTab(currentPlan: _currentPlan),
            PlansTab(
              currentPlan: _currentPlan,
              onPlanChanged: _updatePlan,
            ),
          ],
        ),
      ),
    );
  }
}
