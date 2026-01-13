import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/responsive_layout.dart';

// Screens
import 'home/student_home_screen.dart';
import '../common/search_classes_screen.dart';
import 'agenda/student_agenda_screen.dart';
import 'profile/student_profile_screen.dart';
import 'student_drawer.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentHomeScreen(),
    const SearchClassesScreen(),
    const StudentAgendaScreen(), 
    const StudentProfileScreen(), 
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Common Destinations
    final destinations = [
       const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: AppColors.neonPurple),
        label: 'Inicio',
      ),
      const NavigationDestination(
        icon: Icon(Icons.search),
        selectedIcon: Icon(Icons.search, color: AppColors.neonPurple),
        label: 'Explorar',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today, color: AppColors.neonPurple),
        label: 'Agenda',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppColors.neonPurple),
        label: 'Perfil',
      ),
    ];

    final railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: AppColors.neonPurple),
        label: Text('Inicio'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.search),
        selectedIcon: Icon(Icons.search, color: AppColors.neonPurple),
        label: Text('Explorar'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today, color: AppColors.neonPurple),
        label: Text('Agenda'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppColors.neonPurple),
        label: Text('Perfil'),
      ),
    ];

    return ResponsiveLayout(
      // === MOBILE LAYOUT ===
      mobile: Scaffold(
        drawer: const StudentDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          indicatorColor: AppColors.neonPurple.withOpacity(0.2),
          destinations: destinations,
        ),
      ),
      
      // === DESKTOP LAYOUT ===
      desktop: Scaffold(
        body: Row(
          children: [
            // Side Navigation Rail
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: Colors.white,
              extended: MediaQuery.of(context).size.width >= 1300, // Expand on very large screens
              selectedIconTheme: const IconThemeData(color: AppColors.neonPurple),
              unselectedIconTheme: const IconThemeData(color: Colors.grey),
              selectedLabelTextStyle: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
              leading: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset('assets/images/logo_app.png', height: 40),
              ),
              destinations: railDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            
            // Main Content Area
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
