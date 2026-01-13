import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/neon_widgets.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../models/class_type_model.dart';
import '../../../../models/user_model.dart'; // Added UserModel import

class ManageClassTypesScreen extends StatefulWidget {
  const ManageClassTypesScreen({super.key});

  @override
  State<ManageClassTypesScreen> createState() => _ManageClassTypesScreenState();
}

class _ManageClassTypesScreenState extends State<ManageClassTypesScreen> {
  // Predefined colors for ease of use
  final List<String> _colors = [
    '#39FF14', // Neon Green
    '#D500F9', // Neon Purple
    '#00E5FF', // Neon Cyan
    '#FF4081', // Neon Pink
    '#FFD600', // Neon Yellow
    '#FF3D00', // Neon Orange
    '#76FF03', // Light Green
    '#651FFF', // Deep Purple
  ];

  final List<String> _categories = ['Baile', 'Fitness', 'Salud', 'Arte', 'Otro'];
  final List<String> _audiences = ['Todo Público', 'Mujeres', 'Hombres', 'Niños', 'Adolescentes', 'Adulto Mayor'];

  void _showEditSheet(BuildContext context, {ClassType? type}) {
    final isEditing = type != null;
    final disciplineController = TextEditingController(text: type?.discipline ?? '');
    final levelController = TextEditingController(text: type?.level ?? '');
    final priceController = TextEditingController(text: type?.defaultPrice.toInt().toString() ?? '5000');
    final capacityController = TextEditingController(text: type?.defaultCapacity.toString() ?? '20');
    
    String selectedColor = type?.color ?? _colors[0];
    String selectedCategory = type?.category ?? 'Otro';
    String selectedAudience = type?.targetAudience ?? 'Todo Público';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) { // Use setSheetState for local updates
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
              left: 20, right: 20, top: 20
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Editar Tipo' : 'Nuevo Tipo de Clase', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // Discipline and Level Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: disciplineController,
                        decoration: const InputDecoration(labelText: 'Disciplina (Ej: Salsa)', border: OutlineInputBorder()),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: levelController,
                        decoration: const InputDecoration(labelText: 'Nivel (Ej: Básico)', border: OutlineInputBorder()),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Category & Audience Row
                Row(
                  children: [
                     Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setSheetState(() => selectedCategory = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedAudience,
                        decoration: const InputDecoration(labelText: 'Público', border: OutlineInputBorder()),
                        items: _audiences.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setSheetState(() => selectedAudience = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Color Picker
                const Text('Color Identificador', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: _colors.map((c) {
                    final isSelected = c == selectedColor;
                    final colorHex = int.parse(c.substring(1), radix: 16) + 0xFF000000;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = c),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Color(colorHex),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: [if(isSelected) BoxShadow(color: Color(colorHex).withOpacity(0.6), blurRadius: 8)]
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Defaults Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio Base', prefixText: '\$', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cupos Base', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : NeonButton(
                        text: 'Guardar Tipo', 
                        color: AppColors.neonPurple, 
                        onPressed: () async {
                          if (disciplineController.text.isEmpty || levelController.text.isEmpty) return;
                          
                          setSheetState(() => isLoading = true);
                          try {
                            final firestore = Provider.of<FirestoreService>(context, listen: false);
                            final user = Provider.of<AuthService>(context, listen: false).currentUser;
                            
                            if (user != null) {
                              final discipline = disciplineController.text.trim();
                              final level = levelController.text.trim();
                              final fullName = '$discipline $level';

                              final newType = ClassType(
                                id: type?.id ?? const Uuid().v4(),
                                instructorId: user.uid, // Always user ID for custom
                                name: fullName,
                                discipline: discipline,
                                level: level,
                                targetAudience: selectedAudience, // Save Audience
                                category: selectedCategory,
                                isVerified: type?.isVerified ?? false, // Keep verification status or default false
                                color: selectedColor,
                                defaultPrice: double.tryParse(priceController.text) ?? 0,
                                defaultCapacity: int.tryParse(capacityController.text) ?? 20,
                              );
                              
                              await firestore.addClassType(user.uid, newType);
                              if (context.mounted) Navigator.pop(context);
                            }
                          } catch (e) {
                             setSheetState(() => isLoading = false);
                             if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      ),
                ),
              ],
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestore = Provider.of<FirestoreService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Tipos de Clase'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGreen,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showEditSheet(context),
      ),
      body: StreamBuilder<UserModel?>(
        stream: auth.user,
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
          
          return StreamBuilder<List<ClassType>>(
            stream: firestore.getClassTypes(userSnap.data!.id),
            builder: (context, typesSnap) {
               if (typesSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
               
               final types = typesSnap.data ?? [];
               if (types.isEmpty) {
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.category, size: 80, color: Colors.grey.withOpacity(0.5)),
                       const SizedBox(height: 16),
                       const Text('No has creado tipos de clase.', style: TextStyle(color: Colors.grey)),
                       const SizedBox(height: 8),
                       const Text('Crea uno para agilizar tu agenda.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   )
                 );
               }

               return ListView.builder(
                 padding: const EdgeInsets.all(16),
                 itemCount: types.length,
                 itemBuilder: (context, index) {
                   final type = types[index];
                   final colorCode = int.parse(type.color.substring(1), radix: 16) + 0xFF000000;
                   
                   return Card(
                     margin: const EdgeInsets.only(bottom: 12),
                     color: theme.cardTheme.color,
                     child: ListTile(
                       leading: Container(
                         width: 40, height: 40,
                         decoration: BoxDecoration(color: Color(colorCode), shape: BoxShape.circle),
                         child: type.isVerified ? const Icon(Icons.verified, color: Colors.white, size: 20) : null,
                       ),
                       title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                       subtitle: Text('${type.category} • \$${type.defaultPrice.toInt()}', style: const TextStyle(fontSize: 12)),
                       trailing: PopupMenuButton(
                         icon: const Icon(Icons.more_vert, color: Colors.grey),
                         onSelected: (val) {
                           if (val == 'edit') _showEditSheet(context, type: type);
                           if (val == 'delete') _confirmDelete(context, firestore, type.id);
                         },
                         itemBuilder: (context) => [
                           const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar')])),
                           const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
                         ],
                       ),
                     ),
                   );
                 },
               );
            },
          );
        },
      )
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService firestore, String typeId) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Tipo?'),
        content: const Text('Esto no borrará las clases pasadas, solo quitará este tipo de la lista para nuevas clases.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              firestore.deleteClassType(typeId);
            }, 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
}
