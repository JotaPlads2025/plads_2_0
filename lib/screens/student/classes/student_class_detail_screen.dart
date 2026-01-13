import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/class_model.dart';
import '../../../models/user_model.dart'; // Import UserModel
import '../../../models/access_grant_model.dart'; // Import AccessGrant
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final ClassModel? classData;
  final String? classId;

  const StudentClassDetailScreen({super.key, this.classData, this.classId});

  @override
  State<StudentClassDetailScreen> createState() => _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  ClassModel? _classData;
  bool _isLoading = true;
  bool _isEnrolling = false; // Debounce state
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.classData != null) {
      _classData = widget.classData;
      _isLoading = false;
    } else if (widget.classId != null) {
      _fetchClassData(widget.classId!);
    } else {
      _error = 'No se encontró la clase';
      _isLoading = false;
    }
  }

  Future<void> _fetchClassData(String id) async {
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final cls = await firestoreService.getClassById(id); // Need to implement this in FirestoreService or use getClasses logic
      // Since we don't have getClassById yet, let's assume we can add it or filter from all classes
      // Actually getting a single document is better.
      // For now, let's assume I will add getClassById to FirestoreService next.
      setState(() {
        _classData = cls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar clase: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // If we have classData, show it immediately.
    // If not, we need to fetch it.
    if (_isLoading) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_error != null || _classData == null) {
       return Scaffold(body: Center(child: Text(_error ?? 'Clase no encontrada')));
    }

    final classData = _classData!;
    final currentUser = authService.currentUser; // Synchronous check

    if (currentUser == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator())); 
    }
    
    // We already have currentUser, so we can calculate simple booleans without StreamBuilder if we trust the auth state not to change mid-view (safe assumption for detail view). 
    // However, to be reactive to "purchases" made in this screen (updating wallet), we SHOULD use a StreamBuilder or Consumer on User model.
    // But let's wrap only the enrollment buttons or use a more robust StreamBuilder.
    
    return StreamBuilder<UserModel?>(
      stream: authService.user, 
      initialData: authService.currentUserModel,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));


        final bool isEnrolled = classData.attendeeIds.contains(user.id);
        final bool isFull = classData.attendeeIds.length >= classData.capacity;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              // 1. Hero Image & Back Button (Same as before)
              Positioned(
                top: 0, left: 0, right: 0,
                height: 300,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const NetworkImage('https://picsum.photos/400/300'), 
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40, left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // 2. Content Sheet
              Positioned.fill(
                top: 250,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              classData.title,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.neonGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '\$${NumberFormat('#,###').format(classData.price)}',
                              style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Instructor: ${classData.instructorName}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info Grid
                      Row(
                        children: [
                          _buildInfoChip(Icons.calendar_today, DateFormat('EEE d MMM', 'es_ES').format(classData.date)),
                          const SizedBox(width: 12),
                          _buildInfoChip(Icons.access_time, '${classData.startTime} - ${classData.endTime}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(Icons.location_on, classData.location),
                          const SizedBox(width: 12),
                           _buildInfoChip(
                             Icons.group, 
                             isFull ? 'Agotado' : '${classData.capacity - classData.attendeeIds.length} cupos'
                           ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        classData.description.isNotEmpty ? classData.description : 'Prepárate para una clase increíble donde aprenderás técnica, musicalidad y disfrutarás del baile al máximo.',
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),

                      const Spacer(),

                      StreamBuilder<UserModel?>(
                        stream: Provider.of<AuthService>(context, listen: false).user,
                        builder: (context, snapshot) {
                          final userModel = snapshot.data; 
                          
                          // Check activeSubscriptions
                          bool hasCredit = false;
                          int totalCredits = 0;
                          
                          if (userModel != null) {
                              for (var grant in userModel.activeSubscriptions) {
                                  bool disciplineMatch = grant.discipline == 'All' || grant.discipline == classData.discipline;
                                  if (disciplineMatch && grant.isActive) {
                                      if (grant.type == AccessGrantType.subscription) {
                                          if (grant.expiryDate == null || grant.expiryDate!.isAfter(DateTime.now())) {
                                              hasCredit = true;
                                          }
                                      } else {
                                          if ((grant.remainingClasses ?? 0) > 0) {
                                              hasCredit = true;
                                              totalCredits += (grant.remainingClasses ?? 0);
                                          }
                                      }
                                  }
                              }
                          }
                          // define dummy credits to minimize code change in lines below if possible, OR replace usages below.
                          // Let's replace usages below.

                          // 1. Single Button Fallback (No plans, No credits)
                          if (classData.availablePlans.isEmpty && !hasCredit) {
                             return SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: _buildEnrollButton(
                                context, 
                                label: 'Inscribirse Ahora',
                                isPrimary: true,
                                isEnrolled: isEnrolled,
                                isFull: isFull,
                                onTap: () => _processEnrollment(context, () => firestoreService.enrollInClass(classData.id, user.id)),
                              ),
                            );
                          }

                          // 2. Dual Buttons
                          return Row(
                            children: [
                              // Left: Drop-in OR Use Credit
                              Expanded(
                                child: SizedBox(height: 56, child: _buildEnrollButton(
                                  context,

                                  label: hasCredit ? 'Usar Plan/Pack' : 'Clase Suelta',
                                  subtitle: hasCredit ? '${totalCredits > 0 ? "$totalCredits cupos" : "Suscripción"}' : '\$${classData.price.toInt()}',
                                  isPrimary: hasCredit, // Highlight if using credit
                                  isEnrolled: isEnrolled,
                                  isFull: isFull,
                                  color: hasCredit ? AppColors.neonGreen : Colors.grey.shade800,
                                  onTap: () {
                                     if (hasCredit) {
                                       _processEnrollment(context, () => firestoreService.useSubscriptionAndEnroll(classData.id, user.id));
                                     } else {
                                       _processEnrollment(context, () => firestoreService.enrollInClass(classData.id, user.id));
                                     }
                                  }
                                )),
                              ),
                              const SizedBox(width: 12),
                              
                              // Right: Buy Plan
                              Expanded(
                                child: SizedBox(height: 56, child: _buildEnrollButton(
                                  context,
                                  label: 'Comprar Plan',
                                  isPrimary: !hasCredit, // Highlight if need to buy
                                  isEnrolled: isEnrolled,
                                  isFull: isFull,
                                  onTap: () => _showPurchaseOptions(context, classData, user, firestoreService),
                                )),
                              ),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }



  void _showPurchaseOptions(BuildContext context, ClassModel classData, dynamic user, FirestoreService firestoreService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow it to expand nicely
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color, // Solid background from theme
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)], // Strong shadow to separate from background
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            const Text(
              'Selecciona tu Entrada', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige cómo prefieres acceder a esta clase.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Option 1: Drop-in Card
            _buildOptionCard(
              context: context, 
              title: 'Clase Suelta (Drop-in)', 
              subtitle: 'Acceso único para esta fecha.', 
              price: classData.price, 
              icon: Icons.confirmation_number_outlined,
              color: Colors.orange,
              onTap: () async {
                 Navigator.pop(ctx);
                 _processEnrollment(context, () => firestoreService.enrollInClass(classData.id, user.id));
              }
            ),

            const SizedBox(height: 16),
            if (classData.availablePlans.isNotEmpty) ...[
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 8),
                 child: Text('PACKS Y PLANES RECOMENDADOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
               ),
              
              // Option 2..N: Plans
              ...classData.availablePlans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOptionCard(
                  context: context,
                  title: plan['title'] ?? 'Plan',
                  subtitle: plan['description'] ?? 'Ahorra comprando en pack.',
                  price: (plan['price'] as num).toDouble(),
                  icon: Icons.verified_user_outlined,
                  color: AppColors.neonPurple,
                  isFeatured: true, // Highlight plans
                  onTap: () async {
                    Navigator.pop(ctx);
                    _processEnrollment(context, () => firestoreService.purchasePlanAndEnroll(classData.id, user.id, plan));
                  },
                ),
              )),
            ]
          ],
        ),
      )
    );
  }

  Widget _buildOptionCard({
    required BuildContext context, 
    required String title, 
    required String subtitle, 
    required double price, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    bool isFeatured = false,
  }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isFeatured ? color.withOpacity(0.1) : Theme.of(context).scaffoldBackgroundColor, // Slight tint for featured
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isFeatured ? color : Colors.grey.withOpacity(0.2), width: isFeatured ? 1.5 : 1),
          ),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: color.withOpacity(0.2),
                   shape: BoxShape.circle
                 ),
                 child: Icon(icon, color: color, size: 24),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 2),
                     Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 2, overflow: TextOverflow.ellipsis),
                   ],
                 ),
               ),
               const SizedBox(width: 12),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    Text('\$${NumberFormat('#,###').format(price)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    if (isFeatured) 
                      const Text('MEJOR PRECIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                 ],
               )
            ],
          ),
        ),
      );
  }

  Future<void> _processEnrollment(BuildContext context, Future<void> Function() action) async {
    setState(() => _isEnrolling = true);
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Todo Listo! 🎉')));
        Navigator.pop(context); // Close Screen
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isEnrolling = false);
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.neonPurple),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
  Widget _buildEnrollButton(BuildContext context, {
    required String label, 
    String? subtitle,
    required bool isPrimary, 
    required bool isEnrolled, 
    required bool isFull, 
    required VoidCallback onTap,
    Color? color,
  }) {
    final bgColor = isEnrolled ? Colors.grey : (color ?? (isPrimary ? AppColors.neonPurple : Colors.grey.shade800));
    
    return ElevatedButton(
      onPressed: (isEnrolled || isFull || _isEnrolling) ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isEnrolled ? 0 : 4,
        padding: const EdgeInsets.symmetric(horizontal: 8), 
      ),
      child: _isEnrolling 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isEnrolled ? 'Inscrito' : isFull ? 'Lleno' : label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && !isEnrolled && !isFull)
                 Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
    );
  }
}
