import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../classes/create_class_screen.dart';
import '../classes/class_detail_screen.dart';
import '../classes/class_attendance_screen.dart'; 
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/class_model.dart';
import '../../../models/user_model.dart';

class ClassesTab extends StatefulWidget {
  const ClassesTab({super.key});

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _viewMode = 'calendar'; // 'calendar' or 'list'
  late TabController _managementTabController;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _managementTabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _managementTabController.dispose();
    super.dispose();
  }

  // Helper to filter events for a specific day from the full list
  List<ClassModel> _getEventsForDay(List<ClassModel> allClasses, DateTime day) {
    return allClasses.where((cls) {
      return isSameDay(cls.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonGreen = AppColors.neonGreen;
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    // Optimization: Get ID synchronously if possible
    final currentUser = authService.currentUser;

    if (currentUser != null) {
       return StreamBuilder<List<ClassModel>>(
          stream: firestoreService.getInstructorClasses(currentUser.uid),
          builder: (context, classesSnapshot) {
            if (classesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allClasses = classesSnapshot.data ?? [];
            final activeClasses = allClasses.where((c) => c.status != 'cancelled').toList();
            final cancelledClasses = allClasses.where((c) => c.status == 'cancelled').toList();

            return Column(
              children: [
                // 1. Calendar Header (Collapsible)
                _buildCalendarHeader(theme),

                // 2. Calendar View (Collapsible) - Only show Active Classes
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstChild: _buildCalendarView(theme, neonGreen, activeClasses),
                  secondChild: const SizedBox.shrink(),
                  crossFadeState: _viewMode == 'calendar' ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
                
                // 3. Tab Bar for List vs History
                Container(
                  color: theme.appBarTheme.backgroundColor,
                  child: TabBar(
                    controller: _managementTabController,
                    indicatorColor: neonGreen,
                    labelColor: neonGreen,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Próximas'),
                      Tab(text: 'Historial'),
                      Tab(text: 'Canceladas'),
                    ],
                  ),
                ),

                // 4. Class List
                Expanded(
                  child: TabBarView(
                    controller: _managementTabController,
                    children: [
                      // Upcoming: Active AND Future (or Today)
                      _buildClassList(activeClasses.where((c) => c.date.isAfter(DateTime.now().subtract(const Duration(hours: 4)))).toList()),
                      // History: Past (Time passed) - Only Active Classes? Or all? User said "Clear data", so let's show only active history here.
                      _buildClassList(activeClasses.where((c) => c.date.isBefore(DateTime.now().subtract(const Duration(hours: 4)))).toList(), isHistory: true),
                      // Cancelled List
                      _buildClassList(cancelledClasses, isHistory: true), // Reusing history style (greyed out) for cancelled
                    ],
                  ),
                ),
              ],
            );
          }
       );
    }

    // Fallback if currentUser is null (shouldn't happen if guarded by auth wrapper)
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildCalendarHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.appBarTheme.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                   // Date Picker Logic could go here
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(_viewMode == 'calendar' ? Icons.list : Icons.calendar_today),
                onPressed: () {
                  setState(() {
                    _viewMode = _viewMode == 'calendar' ? 'list' : 'calendar';
                  });
                },
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                backgroundColor: AppColors.neonGreen,
                child: const Icon(Icons.add, color: Colors.black),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CreateClassScreen(initialDate: _selectedDay)));
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(ThemeData theme, Color neonGreen, List<ClassModel> allClasses) {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.week,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _showDayClassesModal(selectedDay, allClasses);
      },
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      eventLoader: (day) => _getEventsForDay(allClasses, day),
      
      // Styles
      headerVisible: false,
      calendarStyle: CalendarStyle(
        defaultTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
        weekendTextStyle: const TextStyle(color: Colors.grey),
        selectedDecoration: BoxDecoration(color: neonGreen, shape: BoxShape.circle),
        selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        todayDecoration: BoxDecoration(color: neonGreen.withOpacity(0.3), shape: BoxShape.circle),
        markerDecoration: const BoxDecoration(color: AppColors.neonPurple, shape: BoxShape.circle),
      ),
    );
  }

  void _showDayClassesModal(DateTime date, List<ClassModel> allClasses) {
    final classes = _getEventsForDay(allClasses, date);
    final dateStr = DateFormat('EEEE d', 'es_ES').format(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true, 
      builder: (context) {
         return DraggableScrollableSheet(
           initialChildSize: 0.5,
           minChildSize: 0.3,
           maxChildSize: 0.9,
           expand: false,
           builder: (_, controller) {
             return ListView(
               controller: controller,
               padding: const EdgeInsets.all(20),
               children: [
                 Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)))),
                 const SizedBox(height: 20),
                 Text('Clases del $dateStr', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 5),
                 Text('${classes.length} clases programadas', style: const TextStyle(color: Colors.grey)),
                 const SizedBox(height: 20),
                 
                 // List inside modal
                 ...classes.map((cls) => Card(
                   margin: const EdgeInsets.only(bottom: 12),
                   color: Theme.of(context).cardTheme.color,
                   child: ListTile(
                     title: Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: Text('${cls.startTime} • ${cls.location}'),
                     trailing: ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen, foregroundColor: Colors.black),
                       onPressed: () {
                         Navigator.pop(context);
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ClassDetailScreen(classData: cls))); 
                       },
                       child: const Text('Ver'),
                     ),
                   ),
                 )),

                 if (classes.isEmpty)
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 40),
                     child: Center(child: Text('No hay clases para este día.', style: TextStyle(color: Colors.grey))),
                   ),
                 
                 const SizedBox(height: 20),
                 SizedBox(
                   width: double.infinity,
                   child: OutlinedButton.icon(
                     onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreateClassScreen(initialDate: date)));
                     }, 
                     icon: const Icon(Icons.add), 
                     label: const Text('Programar Clase')
                   ),
                 )
               ],
             );
           },
         );
      },
    );
  }

  Widget _buildClassList(List<ClassModel> classes, {bool isHistory = false}) {
      if (classes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isHistory ? Icons.history : Icons.event_busy, size: 60, color: Colors.grey.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                isHistory ? 'No tienes clases pasadas.' : 'No hay clases programadas.',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final cls = classes[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Theme.of(context).cardTheme.color,
            child: ListTile(
              leading: Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: isHistory ? Colors.grey.withOpacity(0.2) : AppColors.neonPurple.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(
                   DateFormat('dd\nMMM', 'es_ES').format(cls.date).toUpperCase(),
                   textAlign: TextAlign.center,
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isHistory ? Colors.grey : AppColors.neonPurple)
                 ),
              ),
              title: Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${cls.startTime} • ${cls.location}'),
              trailing: isHistory 
                  ? OutlinedButton(
                      onPressed: () {
                         // Navigator.push(context, MaterialPageRoute(builder: (_) => ClassAttendanceScreen(classId: cls.id)));
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                      child: const Text('Cerrar', style: TextStyle(color: Colors.grey)), 
                    )
                  : ElevatedButton(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ClassDetailScreen(classData: cls)));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen, foregroundColor: Colors.black),
                      child: const Text('Gestionar'),
                    ),
            ),
          );
        },
      );
  }
}
