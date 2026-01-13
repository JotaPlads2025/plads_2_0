import 'package:flutter/material.dart';
import '../../common/qr_scanner_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../repositories/class_repository.dart';
import '../../../services/logic/attendance_logic.dart';
import '../../../models/class_model.dart';
import '../../../models/user_model.dart';

class ClassAttendanceScreen extends StatefulWidget {
  final String classId;

  const ClassAttendanceScreen({super.key, required this.classId});

  @override
  State<ClassAttendanceScreen> createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  bool _isLoading = true;
  ClassModel? _classData;
  
  // New Architecture Components
  final ClassRepository _repository = ClassRepository();
  final AttendanceLogic _logic = AttendanceLogic();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Fetch Class Data via Repository
      final cls = await _repository.getClassById(widget.classId);
      if (cls == null) {
        throw Exception("Clase no encontrada");
      }
      
      // 2. Fetch Registered Users via Repository
      // Only fetch if there are attendees
      final users = cls.attendeeIds.isNotEmpty 
          ? await _repository.getUsersByIds(cls.attendeeIds)
          : <UserModel>[]; // Explicit type to match expected List<UserModel>
      
      // 3. Delegate Merging Logic to Manager
      _logic.loadParticipants(cls, users); // This handles Manual + App users merging
      
      if (mounted) {
        setState(() {
          _classData = cls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_classData == null) return const Scaffold(body: Center(child: Text("Error al cargar datos")));

    // Use pure list from Logic
    final students = _logic.participants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerrar Asistencia'),
        actions: [
          TextButton(
            onPressed: () => _confirmCloseClass(context),
            child: const Text('FINALIZAR', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => QRScannerScreen(
                mode: ScannerMode.instructorCheckIn, 
                classId: widget.classId
              )
            )
          );
          // Refresh data after returning from scanner
          _fetchData();
        },
        label: const Text('Escanear QR'),
        icon: const Icon(Icons.qr_code_scanner),
        backgroundColor: AppColors.neonPurple,
      ),
      body: Column(
        children: [
           Container(
             padding: const EdgeInsets.all(16),
             color: Theme.of(context).cardTheme.color,
             child: Row(
               children: [
                 const Icon(Icons.info_outline, color: Colors.amber),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     'Confirma la asistencia antes de cerrar (${students.length} inscritos).',
                     style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                   ),
                 ),
               ],
             ),
           ),
           Expanded(
             child: students.isEmpty 
               ? const Center(child: Text('No hay alumnos inscritos aún.', style: TextStyle(color: Colors.grey)))
               : ListView.separated(
                 padding: const EdgeInsets.all(16),
                 itemCount: students.length,
                 separatorBuilder: (_, __) => const Divider(),
                 itemBuilder: (context, index) {
                   final s = students[index];
                   final attended = _logic.attendanceMap[s.id] ?? false;
                   final isManual = _logic.isManualUser(s.id);

                   return CheckboxListTile(
                     value: attended,
                     activeColor: AppColors.neonGreen,
                     checkColor: Colors.black,
                     title: Text(
                       s.displayName.isNotEmpty ? s.displayName : 'Alumno sin nombre', 
                       style: const TextStyle(fontWeight: FontWeight.bold)
                     ),
                     subtitle: Text(
                       isManual ? 'Manual (Efectivo/Transferencia)' : s.email,
                       style: TextStyle(color: isManual ? Colors.orange : Colors.grey)
                     ),
                     secondary: CircleAvatar(
                       backgroundColor: isManual ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                       backgroundImage: (s.photoUrl != null && s.photoUrl!.isNotEmpty) ? NetworkImage(s.photoUrl!) : null,
                       child: (s.photoUrl == null || s.photoUrl!.isEmpty) 
                          ? Icon(isManual ? Icons.person_outline : Icons.person, color: isManual ? Colors.orange : Colors.white)
                          : null,
                     ),
                     onChanged: (val) {
                       setState(() {
                         _logic.toggleAttendance(s.id, val ?? false);
                       });
                     },
                   );
                 },
               ),
           ),
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: students.isEmpty ? null : () => _confirmCloseClass(context),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.neonGreen,
                   foregroundColor: Colors.black,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                 ),
                 child: const Text('Confirmar y Cerrar Clase', style: TextStyle(fontWeight: FontWeight.bold)),
               ),
             ),
           )
        ],
      ),
    );
  }

  void _confirmCloseClass(BuildContext context) {
    final presentStudentIds = _logic.getPresentStudentIds();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // Use dialogContext to avoid confusion
        title: const Text('¿Cerrar Clase?'),
        content: Text('Se registrará la asistencia de ${presentStudentIds.length} alumnos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
               Navigator.pop(dialogContext); // Close dialog
               
               setState(() => _isLoading = true);
               try {
                 await _repository.saveAttendance(widget.classId, presentStudentIds);
                 
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Asistencia guardada (${presentStudentIds.length} presentes)'))
                   );
                   Navigator.pop(context); // Close screen
                 }
               } catch (e) {
                 if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
               }
            }, 
            child: const Text('Confirmar', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
