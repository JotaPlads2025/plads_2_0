import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'teacher_profile_screen.dart';

class FavoriteTeachersScreen extends StatelessWidget {
  const FavoriteTeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Favorites
    final List<Map<String, dynamic>> favorites = [
      {
        'id': 'mock_1',
        'name': 'Juan Pérez',
        'specialty': 'Bachata & Salsa',
        'image': 'https://picsum.photos/300/200',
        'rating': 4.9
      },
      {
        'id': 'mock_2',
        'name': 'Ana Silva',
        'specialty': 'Kizomba',
        'image': 'https://picsum.photos/303/200',
        'rating': 4.7
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Suscripciones'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: favorites.isEmpty 
        ? const Center(child: Text('Aún no sigues a ningún profesor.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final teacher = favorites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(teacher['image']),
                  ),
                  title: Text(teacher['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(teacher['specialty']),
                  trailing: Wrap(
                     spacing: 8,
                     crossAxisAlignment: WrapCrossAlignment.center,
                     children: [
                       const Icon(Icons.star, color: Colors.amber, size: 16),
                       Text(teacher['rating'].toString()),
                       const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                     ],
                  ),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfileScreen(
                       instructorId: teacher['id'],
                       teacherName: teacher['name'],
                       image: teacher['image'],
                     )));
                  },
                ),
              );
            },
        ),
    );
  }
}
