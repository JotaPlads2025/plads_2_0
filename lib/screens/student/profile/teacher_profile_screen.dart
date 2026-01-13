import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TeacherProfileScreen extends StatefulWidget {
  final String teacherName;
  final String image;

  const TeacherProfileScreen({super.key, required this.teacherName, required this.image});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Image.network(widget.image, fit: BoxFit.cover),
                   Container(
                     decoration: const BoxDecoration(
                       gradient: LinearGradient(
                         colors: [Colors.transparent, Colors.black],
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                       )
                     ),
                   ),
                   Positioned(
                     bottom: 20,
                     left: 20,
                     right: 20,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(widget.teacherName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                         const Text('Instructor de Bachata & Salsa', style: TextStyle(color: Colors.white70)),
                         const SizedBox(height: 12),
                         Row(
                           children: [
                             const Icon(Icons.star, color: Colors.amber, size: 20),
                             const Text(' 4.9 ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                             const Text('(120 Reseñas)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                             const Spacer(),
                             ElevatedButton.icon(
                               onPressed: () {
                                 setState(() => _isSubscribed = !_isSubscribed);
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(_isSubscribed ? '¡Te has suscrito a ${widget.teacherName}!' : 'Suscripción cancelada'))
                                 );
                               },
                               icon: Icon(_isSubscribed ? Icons.notifications_active : Icons.notifications_none),
                               label: Text(_isSubscribed ? 'Suscrito' : 'Suscribirse'),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: _isSubscribed ? Colors.grey : AppColors.neonPurple,
                                 foregroundColor: Colors.white,
                               ),
                             )
                           ],
                         )
                       ],
                     ),
                   )
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
               TabBar(
                 controller: _tabController,
                 labelColor: AppColors.neonPurple,
                 unselectedLabelColor: Colors.grey,
                 indicatorColor: AppColors.neonPurple,
                 tabs: const [
                   Tab(text: 'Clases'),
                   Tab(text: 'Reseñas'),
                   Tab(text: 'Videos'),
                 ],
               ),
            ),
            pinned: true,
          )
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildClassesTab(),
            _buildReviewsTab(),
            _buildVideosTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Próximas Clases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildClassItem('Bachata Sensual', 'Hoy, 19:00', 'Academia Plads'),
        _buildClassItem('Salsa Cubana', 'Mañana, 20:00', 'Sede Providencia'),
        _buildClassItem('Taller Coreográfico', 'Sábado, 11:00', 'Sede Las Condes'),
      ],
    );
  }

  Widget _buildClassItem(String title, String time, String location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.neonPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.event, color: AppColors.neonPurple),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$time • $location'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: CircleAvatar(child: Text('A')),
          title: Text('Andrea M.'),
          subtitle: Text('¡Excelente clase! Explica muy bien los pasos.'),
          trailing: Icon(Icons.star, color: Colors.amber, size: 16),
        ),
        Divider(),
        ListTile(
          leading: CircleAvatar(child: Text('C')),
          title: Text('Carlos F.'),
          subtitle: Text('Muy buena energía, recomendadísimo.'),
          trailing: Icon(Icons.star, color: Colors.amber, size: 16),
        ),
      ],
    );
  }

  Widget _buildVideosTab() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: List.generate(4, (index) => Container(
        color: Colors.black12,
        child: const Center(child: Icon(Icons.play_circle_outline, size: 50, color: Colors.grey)),
      )),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
