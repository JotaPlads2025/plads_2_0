
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../widgets/neon_widgets.dart';
import '../../../../../services/academy_service.dart';
import '../../../../../models/room_model.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final academyService = Provider.of<AcademyService>(context);
    final academy = academyService.currentAcademy;
    
    if (academy == null) return const Center(child: Text('Error: No Academy Found'));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Instalaciones / Salas'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddRoomDialog(context, academy.id),
      ),
      body: academy.rooms.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No tienes salas registradas aún.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Agrega una sala para asignarla a tus clases.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: academy.rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final room = academy.rooms[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.meeting_room, color: AppColors.neonPurple),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Capacidad: ${room.capacity} personas', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          if (room.description != null && room.description!.isNotEmpty)
                            Text(room.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        // Confirm deletion
                         showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar Sala'),
                            content: Text('¿Estás seguro de que deseas eliminar la sala "${room.name}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  academyService.removeRoom(academyId: academy.id, roomId: room.id);
                                }, 
                                child: const Text('Eliminar', style: TextStyle(color: Colors.red))
                              ),
                            ],
                          )
                        );
                      },
                    )
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showAddRoomDialog(BuildContext context, String academyId) {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Sala'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre (ej. Sala A)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidad', border: OutlineInputBorder()),
            ),
             const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción (Opcional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && capCtrl.text.isNotEmpty) {
                final newRoom = RoomModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  capacity: int.tryParse(capCtrl.text) ?? 10,
                  description: descCtrl.text,
                );
                
                Provider.of<AcademyService>(context, listen: false).addRoom(
                  academyId: academyId,
                  room: newRoom
                );
                
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
