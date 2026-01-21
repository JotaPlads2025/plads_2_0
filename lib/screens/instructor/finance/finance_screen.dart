import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../models/user_model.dart';
import '../../../../theme/app_theme.dart';
import 'tabs/accounting_tab.dart';
import 'tabs/plans_tab.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = Provider.of<AuthService>(context).currentUserModel;
    final currentPlan = userModel?.planType ?? 'commission';

    Future<void> updatePlan(String newPlan) async {
      try {
        final userId = userModel?.id;
        if (userId != null) {
          await Provider.of<FirestoreService>(context, listen: false).updateUserFields(userId, {'planType': newPlan});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Plan actualizado a: $newPlan'), backgroundColor: AppColors.neonGreen),
            );
          }
          // Force refresh of user data? AuthService stream handles this usually.
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cambiar plan: $e'), backgroundColor: Colors.red),
            );
        }
      }
    }

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
            AccountingTab(currentPlan: currentPlan), 
            PlansTab(
              currentPlan: currentPlan,
              onPlanChanged: updatePlan,
            ),
          ],
        ),
      ),
    );
  }
}
