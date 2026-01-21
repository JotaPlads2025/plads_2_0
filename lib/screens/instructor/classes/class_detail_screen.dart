import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/class_model.dart';
import '../../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../common/qr_scanner_screen.dart';
import 'class_attendance_screen.dart'; // Import Attendance Screen

class ClassDetailScreen extends StatefulWidget {
  final ClassModel classData;

  const ClassDetailScreen({super.key, required this.classData});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    // Load existing manual attendees
    _students = List<Map<String, dynamic>>.from(widget.classData.manualAttendees);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final primaryColor = const Color(0xFFD000FF); // Neon Purple
    final cashColor = const Color(0xFF39FF14); // Neon Green
    final transferColor = Colors.blueAccent;

    final formattedDate = DateFormat('EEEE d MMMM, yyyy', 'es_ES').format(widget.classData.date);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de Clase'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Clase',
            onPressed: () {
               // Placeholder for Edit functionality
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionalidad de Edición próximamente')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            color: theme.iconTheme.color,
            onPressed: () => _showShareQR(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Class Info Header
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.cardTheme.color,
            child: Column(
              children: [
                Text(
                  widget.classData.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.classData.startTime} - ${widget.classData.endTime}', 
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                     Text(
                      widget.classData.location,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(context, '${widget.classData.attendeeIds.length + _students.length}/${widget.classData.capacity}', 'Cupos', Icons.group),
                    _buildStat(context, '\$${NumberFormat('#,###').format(widget.classData.price)}', 'Valor Ticket', Icons.local_offer),
                    if (widget.classData.status == 'cancelled')
                       _buildStat(context, 'Cancelada', 'Estado', Icons.cancel, color: Colors.red)
                    else 
                       _buildStat(context, 'Activa', 'Estado', Icons.check_circle, color: cashColor),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.classData.status != 'cancelled')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Cancelar Clase', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 1), // Divider spacing

          // 2. Attendance List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Asistentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(
                           builder: (_) => ClassAttendanceScreen(classId: widget.classData.id)
                         ));
                      },
                      icon: const Icon(Icons.checklist, color: AppColors.neonGreen),
                      label: const Text('Pasar Lista', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showAddStudentModal(context),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: firestoreService.getClassAttendees(widget.classData.attendeeIds),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                 }
                 
                 final attendees = snapshot.data ?? [];
                 
                 // Combine with local manual students (if any)
                 // For now, we mainly show the real attendees
                 
                 if (attendees.isEmpty && _students.isEmpty) {
                   return const Center(child: Text('Aún no hay inscritos.', style: TextStyle(color: Colors.grey)));
                 }

                 return ListView(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   children: [
                     // Real App Users
                     ...attendees.map((user) {
                        final hasAttended = widget.classData.attendance.containsKey(user.id);
                        return _buildStudentTile(context, user.displayName, 'Pagado vía App', true, isLocal: false, hasAttended: hasAttended);
                     }),
                     
                     // Manual Entries (Mock/Local)
                     ..._students.map((s) => _buildStudentTile(context, s['name'], s['status'] == 'paid_cash' ? 'Efectivo' : 'Transferencia', false, isLocal: true)),
                   ],
                 );
              }
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           Navigator.push(context, MaterialPageRoute(
             builder: (_) => QRScannerScreen(
               mode: ScannerMode.instructorCheckIn,
               classId: widget.classData.id,
             )
           ));
        },
        backgroundColor: AppColors.neonPurple, // Make it pop
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Escanear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, String name, String status, bool isAppUser, {bool isLocal = false, bool hasAttended = false}) {
     final theme = Theme.of(context);
     final primaryColor = const Color(0xFFD000FF);
     
     return Card(
        color: theme.cardTheme.color,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
             backgroundColor: isAppUser ? primaryColor.withOpacity(0.2) : Colors.grey.shade300,
             child: Icon(Icons.person, color: isAppUser ? primaryColor : Colors.grey),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(status, style: TextStyle(color: isAppUser ? primaryColor : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
          trailing: hasAttended 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null, 
        ),
     );
  }


  Widget _buildStat(BuildContext context, String value, String label, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color ?? theme.iconTheme.color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showAddStudentModal(BuildContext context) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddStudentModal(
          classId: widget.classData.id, 
          defaultPrice: widget.classData.price
        ), 
      ).then((result) async {
        if (result != null) {
          try {
             final firestore = Provider.of<FirestoreService>(context, listen: false);
             
             // Extract payment details
             // Note: result['status'] is 'paid_cash' or 'paid_transfer' based on AddStudentModal
             double amount = widget.classData.price;
             // AddStudentModal could return the actual amount if it was editable, 
             // but current implementation allows editing amount but returns a map.
             // Let's check AddStudentModal implementation. 
             // It returns a map with 'name', 'status', 'avatar'. 
             // It prints amount in SnackBar but doesn't return it in the map clearly.
             // We need to update AddStudentModal to return amount too.
             // For now assuming default price or extracting if possible.
             // Let's assume AddStudentModal returns amount in the map.
             
             double paidAmount = result['amount'] ?? widget.classData.price;

             await firestore.addManualAttendee(
               widget.classData.id, 
               result, 
               paidAmount,
               result['status'] == 'paid_cash' ? 'cash' : 'transfer'
             );

             setState(() {
               result['attended'] = false;
               _students.add(result);
             });
          } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
          }
        }
      });
    }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Clase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta acción notificará a todos los alumnos inscritos.\n', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('Se recomienda contactar a los alumnos para gestionar la devolución.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de cancelación',
                hintText: 'Ej: Enfermedad, clima...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes ingresar un motivo')));
                 return;
              }
              Navigator.pop(ctx);
              try {
                final firestore = Provider.of<FirestoreService>(context, listen: false);
                await firestore.cancelClass(widget.classData.id, reasonController.text);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clase cancelada y alumnos notificados.')));
                   Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('Confirmar Cancelación', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  void _showShareQR(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Código de Inscripción 📲', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Pide a tus alumnos que escaneen este código desde la App Plads para inscribirse automáticamente.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            QrImageView(
              data: 'plads_class:${widget.classData.id}',
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 32),
            const Text('¡Venta Rápida! ⚡', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} // Close _ClassDetailScreenState

class AddStudentModal extends StatefulWidget {
  final String classId;
  final double defaultPrice;

  const AddStudentModal({super.key, required this.classId, required this.defaultPrice});

  @override
  State<AddStudentModal> createState() => _AddStudentModalState();
}

class _AddStudentModalState extends State<AddStudentModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  late TextEditingController _amountController; 
  bool _isAnonymous = false;
  String _paymentMethod = 'cash'; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    String priceStr = widget.defaultPrice.toString();
    if (priceStr.endsWith('.0')) priceStr = priceStr.substring(0, priceStr.length - 2);
    _amountController = TextEditingController(text: priceStr);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonPurple = AppColors.neonPurple;
    final neonGreen = AppColors.neonGreen;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
          ),
          
          Text('Agregar Asistente a Clase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),

          TabBar(
            controller: _tabController,
            labelColor: neonPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: neonPurple,
            tabs: const [
              Tab(text: 'Escanea QR', icon: Icon(Icons.qr_code)),
              Tab(text: 'Manual / Pago', icon: Icon(Icons.attach_money)),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. QR Code View (Dynamic Data)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: QrImageView(
                        data: 'plads_class:${widget.classId}', // Encode Class ID
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Muestra este código al alumno',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                      child: Text(
                        'El alumno debe escanearlo para pagar y registrarse en ESTA clase específica.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                // 2. Manual Entry View
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          enabled: !_isAnonymous,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Alumno',
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: theme.cardTheme.color,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Alumno Anónimo'),
                          subtitle: const Text('Registrar solo el cupo y pago'),
                          value: _isAnonymous,
                          activeColor: neonPurple,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              _isAnonymous = val;
                              if (val) _nameController.text = "Anónimo";
                              else _nameController.text = "";
                            });
                          },
                        ),
                        const Divider(height: 32),
                        
                        const Text('Detalles del Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            labelText: 'Monto Pagado (\$)',
                            prefixIcon: const Icon(Icons.attach_money),
                            filled: true,
                            fillColor: theme.cardTheme.color,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentMethodOption(
                                context,
                                label: 'Efectivo',
                                icon: Icons.money_off,
                                value: 'cash',
                                isSelected: _paymentMethod == 'cash',
                                color: neonGreen,
                                onTap: () => setState(() => _paymentMethod = 'cash'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPaymentMethodOption(
                                context,
                                label: 'Transferencia',
                                icon: Icons.account_balance,
                                value: 'transfer',
                                isSelected: _paymentMethod == 'transfer',
                                color: Colors.blueAccent,
                                onTap: () => setState(() => _paymentMethod = 'transfer'),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_amountController.text.isEmpty) return;
                              
                              final newStudent = {
                                'name': _nameController.text.isEmpty ? 'Anónimo' : _nameController.text,
                                'status': _paymentMethod == 'cash' ? 'paid_cash' : 'paid_transfer',
                                'avatar': '',
                                'amount': double.tryParse(_amountController.text) ?? 0.0,
                              };

                              Navigator.pop(context, newStudent);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('✅ Pago de \$${_amountController.text} registrado ($_paymentMethod)')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Registrar Alumno y Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(BuildContext context, {
    required String label, 
    required IconData icon, 
    required String value, 
    required bool isSelected, 
    required Color color,
    required VoidCallback onTap
  }) {
    final theme = Theme.of(context);
    final borderColor = isSelected ? color : Colors.grey.shade800;
    final bgColor = isSelected ? color.withOpacity(0.2) : theme.cardTheme.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
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
// _showShareQR moved up.
}
