import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../student/classes/student_class_detail_screen.dart'; // Corrected Path
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

enum ScannerMode { studentJoinClass, instructorCheckIn }

class QRScannerScreen extends StatefulWidget {
  final ScannerMode mode;
  final String? classId; // Required for instructorCheckIn

  const QRScannerScreen({
    super.key, 
    this.mode = ScannerMode.studentJoinClass, 
    this.classId
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false; // Prevent double scanning

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSuccess({required bool isStudent}) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 80),
            const SizedBox(height: 20),
            Text(isStudent ? '¡Bienvenido!' : '¡Asistencia Registrada!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(isStudent ? 'Disfruta tu clase' : 'Alumno marcado correctamente', style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close modal
                Navigator.pop(context); // Close scanner
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
              ),
              child: const Text('Entendido')
            )
          ],
        ),
      )
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        debugPrint('Barcode found! $code');

        if (widget.mode == ScannerMode.studentJoinClass) {
          // --- STUDENT MODE: Scan Class QR ---
          if (code.startsWith('plads_class:')) {
              _hasScanned = true;
              final classId = code.split(':')[1];
              final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';

              if (userId.isEmpty) {
                _showError('Error: Usuario no identificado');
                return;
              }

              final firestore = Provider.of<FirestoreService>(context, listen: false);
              
              // Mark Attendance
              firestore.markAttendance(classId, userId).then((_) {
                 _showSuccess(isStudent: true);
              }).catchError((e) {
                 _showError(e.toString().replaceAll('Exception: ', ''));
                 Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _hasScanned = false);
                 });
              });
          }
        } else {
          // --- INSTRUCTOR MODE: Scan Student QR or Class Ticket ---
           String? studentId;
           
           if (code.startsWith('plads_user:')) {
             // Format: plads_user:<uid>
             studentId = code.split(':')[1];
           } 
           else if (code.contains('_')) {
             // Format: <classId>_<userId> (Specific Ticket)
             final parts = code.split('_');
             if (parts.length == 2) {
                final scannedClassId = parts[0];
                final scannedUserId = parts[1];
                
                // Verify this ticket is for the CORRECT class
                if (scannedClassId == widget.classId) {
                  studentId = scannedUserId;
                } else {
                   _showError('Este ticket es para otra clase');
                   return;
                }
             }
           }

           if (studentId != null) {
             _hasScanned = true;
             final classId = widget.classId;

             if (classId == null) {
               _showError('Error: Clase no especificada');
               return;
             }

             final firestore = Provider.of<FirestoreService>(context, listen: false);

             // Mark Attendance
             firestore.markAttendance(classId, studentId).then((_) {
                _showSuccess(isStudent: false);
             }).catchError((e) {
                _showError(e.toString().replaceAll('Exception: ', ''));
                Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _hasScanned = false);
                 });
             });
           }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.mode == ScannerMode.studentJoinClass ? 'Escanear Clase' : 'Escanear Alumno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            color: Colors.white,
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            color: Colors.white,
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neonPurple, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                  child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 100)
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código del Instructor',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
