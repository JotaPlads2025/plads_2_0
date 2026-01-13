import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../widgets/neon_widgets.dart';
import '../../../../../services/academy_service.dart';
import '../../../../../models/staff_member.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final academyService = Provider.of<AcademyService>(context);
    final academy = academyService.currentAcademy;

    if (academy == null) return const Center(child: Text('Error: No Academy'));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Equipo / Staff'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddStaffDialog(context, academy.id),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.neonPurple),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Los miembros del staff pueden tomar asistencia y ver detalles de las clases asignadas.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text('Miembros actuales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          academy.staff.isEmpty 
          ? const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Aún no has agregado miembros a tu equipo.', style: TextStyle(color: Colors.grey)),
            ))
          : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: academy.staff.length,
            separatorBuilder: (_,__) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final member = academy.staff[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: member.color ?? Colors.grey,
                      child: Text(member.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(member.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: member.status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.role, 
                            style: TextStyle(
                              fontSize: 10, 
                              color: member.status == 'Active' ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(member.status == 'Active' ? 'Activo' : 'Pendiente', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey), 
                        onPressed: () {
                           Provider.of<AcademyService>(context, listen: false).removeStaff(academyId: academy.id, staffEmail: member.email);
                        }
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context, String academyId) {
    final emailCtrl = TextEditingController();
    String selectedRole = 'Instructor';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar Miembro'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ingresa el correo electrónico de la persona que quieres invitar a tu equipo.'),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                ),
                 const SizedBox(height: 12),
                 DropdownButtonFormField<String>(
                   value: selectedRole,
                   items: ['Instructor', 'Assistant', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                   onChanged: (val) {
                     if(val != null) setDialogState(() => selectedRole = val);
                   },
                   decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                 )
              ],
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white),
            onPressed: () {
              if (emailCtrl.text.isNotEmpty) {
                final newMember = StaffMember(
                  email: emailCtrl.text,
                  name: emailCtrl.text.split('@')[0],
                  role: selectedRole,
                  status: 'Pending',
                  color: Colors.primaries[emailCtrl.text.length % Colors.primaries.length],
                );

                Provider.of<AcademyService>(context, listen: false).addStaff(
                  academyId: academyId, 
                  staffMember: newMember
                );
                
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enviar Invitación'),
          ),
        ],
      ),
    );
  }
}
