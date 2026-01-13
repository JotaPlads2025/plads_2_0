
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../services/firestore_service.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../models/class_model.dart';
import '../../../../../models/user_model.dart';
import '../../../../../models/academy_model.dart';

class AcademyScheduleScreen extends StatefulWidget {
  const AcademyScheduleScreen({super.key});

  @override
  State<AcademyScheduleScreen> createState() => _AcademyScheduleScreenState();
}

class _AcademyScheduleScreenState extends State<AcademyScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text("No autorizado"));

    return FutureBuilder<AcademyModel?>(
      future: user != null ? firestore.getInstructorAcademy(user.uid) : Future.value(null),
      builder: (context, academySnapshot) {
        if (academySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final academy = academySnapshot.data;
        // If no academy, or no rooms, show empty or handle as needed.
        // Assuming we want to show NOTHING if not part of academy rooms.
        final validRooms = academy?.rooms.map((r) => r.name).toSet() ?? {};
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Agenda de Academia'),
            backgroundColor: theme.appBarTheme.backgroundColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month), 
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context, 
                    initialDate: _selectedDate, 
                    firstDate: DateTime(2023), 
                    lastDate: DateTime(2030)
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                }
              ),
            ],
          ),
          body: StreamBuilder<List<ClassModel>>(
            stream: firestore.getInstructorClasses(user!.uid),
            builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
               }
               
               if (!snapshot.hasData || snapshot.data!.isEmpty) {
                 return const Center(child: Text("No hay clases registradas."));
               }

               final allClasses = snapshot.data!;
               
               // Filter by Date AND Valid Rooms
               // Robustness: Normalize strings (trim + uppercase)
               final normalizedValidRooms = validRooms.map((e) => e.trim().toUpperCase()).toSet();
               
               final dayClasses = allClasses.where((c) {
                 final isDay = isSameDay(c.date, _selectedDate);
                 
                 // If no rooms defined in Academy, show ALL classes (fallback)
                 if (normalizedValidRooms.isEmpty) return isDay;

                 final loc = c.location.trim().toUpperCase();
                 
                 // Check if the class location matches ANY valid room (exact or contains)
                 // e.g. "PLADS STUDIO - SALA B" contains "SALA B" -> Match!
                 final isAcademyRoom = normalizedValidRooms.any((room) => loc.contains(room));
                 
                 return isDay && isAcademyRoom;
               }).toList();
               
               if (dayClasses.isEmpty) {
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(DateFormat('EEEE d MMMM', 'es_ES').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                       const SizedBox(height: 10),
                       const Text("No hay clases de academia para este día.", style: TextStyle(color: Colors.grey)),
                     ],
                   ),
                 );
               }

               // Group by Room (Location)
               final Map<String, List<ClassModel>> classesByRoom = {};
               for (var cls in dayClasses) {
                  if (!classesByRoom.containsKey(cls.location)) {
                    classesByRoom[cls.location] = [];
                  }
                  classesByRoom[cls.location]!.add(cls);
               }

               // Sort rooms alphabetically
               final sortedRooms = classesByRoom.keys.toList()..sort();

               return Column(
                 children: [
                    Container(
                     padding: const EdgeInsets.all(12),
                     width: double.infinity,
                     color: theme.cardTheme.color,
                     child: Text(
                       DateFormat('EEEE d MMMM, yyyy', 'es_ES').format(_selectedDate).toUpperCase(),
                       textAlign: TextAlign.center,
                       style: const TextStyle(fontWeight: FontWeight.bold),
                     ),
                   ),
                   Expanded(
                     child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedRooms.length,
                        itemBuilder: (context, index) {
                          final room = sortedRooms[index];
                          final roomClasses = classesByRoom[room]!;
                          
                          // Sort by time
                          roomClasses.sort((a, b) => a.startTime.compareTo(b.startTime));
              
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  room, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: isDark ? Colors.white : Colors.black87
                                  )
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Events Timeline
                              ...roomClasses.map((cls) {
                                final color = Color(int.parse(cls.color.replaceAll('#', '0xFF')));
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12, left: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color,
                                    border: Border(left: BorderSide(color: color, width: 4)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                    ]
                                  ),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${cls.startTime} - ${cls.endTime}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(cls.title, style: const TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                      const Spacer(),
                                      Chip(
                                        label: Text(cls.instructorName, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                        backgroundColor: color,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      )
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                     ),
                   ),
                 ],
               );
            }
          ),
        );
      }
    );

  }
}
