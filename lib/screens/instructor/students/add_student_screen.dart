import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/student_model.dart';
import '../../../models/access_grant_model.dart';
import '../../../widgets/neon_widgets.dart';
import '../../../theme/app_theme.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  StudentStatus _selectedStatus = StudentStatus.activePlan;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      
      // Basic student data
      // Note: Since this is a "Ghost" student (manual entry), they might not have a real UID yet.
      // We will let Firestore generate an ID or use a placeholder if we use add().
      // For now, we'll create a StudentModel. 
      // Ideally, the Service should handle ID generation for manual entries.
      // But StudentModel requires an ID. 
      // We will pass an empty ID and let the service handle it or generate one here.
      
      final newStudent = StudentModel(
        id: '', // Service will assign ID
        name: _nameController.text.trim(),
        email: _emailController.text.trim(), // Optional but good for matching later or invites
        status: _selectedStatus,
        joinDate: DateTime.now(),
        // Default values for new student
        activeSubscriptions: _selectedStatus == StudentStatus.activePlan 
            ? [
                AccessGrant(
                  id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  name: 'Plan Mensual Inicial',
                  type: AccessGrantType.subscription, // Default manual creation to subscription? Or Pack?
                  instructorId: Provider.of<AuthService>(context, listen: false).currentUser!.uid,
                  expiryDate: DateTime.now().add(const Duration(days: 30)),
                  discipline: 'All', // Full access
                  level: 'All'
                )
              ]
            : [],
      );

      await firestore.addStudent(newStudent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alumno agregado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear alumno: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Alumno'),
        backgroundColor: Colors.transparent, // Neon aesthetic
        elevation: 0,
      ),
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Datos del Alumno',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              // Name
              NeonTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.person_outline,
                accentColor: AppColors.neonGreen,
              ),
              const SizedBox(height: 16),
              
              // Email (Optional but recommended)
              NeonTextField(
                controller: _emailController,
                label: 'Correo (Opcional)',
                icon: Icons.email_outlined,
                accentColor: AppColors.neonGreen,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Phone (Optional - UI only for now if model doesn't support it yet)
              NeonTextField(
                controller: _phoneController,
                label: 'Teléfono (Opcional)',
                icon: Icons.phone_outlined,
                accentColor: AppColors.neonGreen,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Plan Inicial',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              // Plan Type Selection
              Row(
                children: [
                  Expanded(
                    child: _buildPlanOption(
                      label: 'Mensualidad',
                      value: StudentStatus.activePlan,
                      icon: Icons.calendar_today,
                      color: AppColors.neonPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPlanOption(
                      label: 'Clase Suelta',
                      value: StudentStatus.dropIn,
                      icon: Icons.confirmation_number_outlined,
                      color: AppColors.neonBlue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : NeonButton(
                      text: 'GUARDAR ALUMNO',
                      onPressed: _saveStudent,
                      color: AppColors.neonGreen,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption({
    required String label,
    required StudentStatus value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedStatus == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade800,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
