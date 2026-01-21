import '../models/user_model.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final int monthlyCost;
  final double commissionRate;
  final List<String> features;
  final String recommendedFor; // "Ideal para..."

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyCost,
    required this.commissionRate,
    required this.features,
    required this.recommendedFor,
  });
}

class SubscriptionService {
  // Define Plans
  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'commission',
      name: 'Plan Comisión',
      monthlyCost: 0,
      commissionRate: 0.10,
      recommendedFor: 'Instructores que inician (< \$300k/mes)',
      features: [
        'Agendamiento Ilimitado',
        'Herramientas de gestión',
        'Perfil Público',
        'Soporte Estándar',
      ],
    ),
    SubscriptionPlan(
      id: 'basic',
      name: 'Plan Básico',
      monthlyCost: 14990,
      commissionRate: 0.05,
      recommendedFor: 'Profesores estables (> \$300k/mes)',
      features: [
        'Todo lo del Plan Comisión',
        'Verificación de Perfil (Blue tick)',
        'Soporte Prioritario',
        'Email Marketing',
        'Estadísticas Básicas',
      ],
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Plan Pro',
      monthlyCost: 29990,
      commissionRate: 0.029,
      recommendedFor: 'Academias y Alto Volumen (> \$715k/mes)',
      features: [
        'Todo lo del Plan Básico',
        'Comisión más baja (2.9%)',
        'Asistente IA Marketing',
        'Mi Academia (Multi-sede)',
        'Analítica Avanzada',
      ],
    ),
  ];

  // Logic
  SubscriptionPlan getPlan(String planId) {
    return plans.firstWhere((p) => p.id == planId, orElse: () => plans.first);
  }

  double calculateFee(UserModel user, double transactionAmount) {
    final plan = getPlan(user.planType);
    return transactionAmount * plan.commissionRate;
  }

  bool canAccessAcademy(UserModel user) {
    return user.planType == 'pro';
  }
  
  bool isVerified(UserModel user) {
    return user.planType == 'basic' || user.planType == 'pro';
  }
}
