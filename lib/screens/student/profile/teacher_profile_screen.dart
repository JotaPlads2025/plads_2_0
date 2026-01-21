import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../classes/student_class_detail_screen.dart';
import '../../common/chat_screen.dart'; // Import ChatScreen
import '../../../services/auth_service.dart'; // Import AuthService

class TeacherProfileScreen extends StatefulWidget {
  final String instructorId;
  final String? teacherName;
  final String? image;

  const TeacherProfileScreen({super.key, required this.instructorId, this.teacherName, this.image});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSubscribed = false;
  UserModel? _instructor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchInstructorData();
  }

  Future<void> _fetchInstructorData() async {
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final user = await firestore.getUserProfile(widget.instructorId);
      if (mounted) {
        setState(() {
          _instructor = user;
          _isLoading = false;
        });
        // DEBUG: Debug success
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID: ${widget.instructorId}, Plan: ${user?.planType}')));
      }
    } catch (e) {
      debugPrint('Error fetching instructor: $e');
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando perfil: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use fetched data or fallback to passed data
    final name = _instructor?.displayName ?? widget.teacherName ?? 'Instructor';
    
    // Improved Photo Logic: Check non-null AND non-empty
    String? validPhotoUrl = _instructor?.photoUrl;
    if (validPhotoUrl != null && validPhotoUrl.trim().isEmpty) validPhotoUrl = null;
    final photoUrl = validPhotoUrl ?? widget.image ?? 'https://i.pravatar.cc/300';
    
    final planType = _instructor?.planType.toLowerCase() ?? '';
    
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
                   Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey.shade900, child: const Icon(Icons.person, size: 50, color: Colors.white))),
                   Container(
                     decoration: const BoxDecoration(
                       gradient: LinearGradient(
                         colors: [Colors.transparent, Colors.black],
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         stops: [0.2, 1.0], 
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
                         Row(
                           children: [
                             Text(
                               name, 
                               style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                             ),
                             if (planType == 'basic' || planType == 'pro') ...[
                               const SizedBox(width: 8),
                               const Icon(Icons.verified, color: Colors.blue, size: 24),
                             ]
                           ],
                         ),
                         Text(_instructor?.bio ?? 'Instructor de Plads', style: const TextStyle(color: Colors.white70)),
                         const SizedBox(height: 12),
                         const SizedBox(height: 12),
                         Row(
                           children: [
                             // Contact Button
                             ElevatedButton.icon(
                               onPressed: () async {
                                  final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
                                  if (currentUser == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para contactar.')));
                                    return;
                                  }

                                  final firestore = Provider.of<FirestoreService>(context, listen: false);
                                  
                                  try {
                                    // 1. Get/Create Chat
                                    final chatId = await firestore.getOrCreateChatInTransaction(
                                      currentUser.uid, 
                                      widget.instructorId, 
                                      currentUser.displayName ?? 'Alumno',
                                      _instructor?.displayName ?? widget.teacherName ?? 'Instructor'
                                    );
                                    
                                    // 2. Navigate
                                    if (context.mounted) {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: chatId, 
                                          otherUserName: _instructor?.displayName ?? widget.teacherName ?? 'Instructor', 
                                          otherUserId: widget.instructorId
                                        )
                                      ));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir chat: $e')));
                                    }
                                  }
                               },
                               icon: const Icon(Icons.chat_bubble_outline),
                               label: const Text('Contactar / Mensaje'),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: AppColors.neonPurple,
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
            // ...
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
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    
    return StreamBuilder<List<ClassModel>>(
      stream: firestore.getInstructorClasses(widget.instructorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final classes = snapshot.data ?? [];
        
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 60, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No hay clases programadas', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return _buildClassItem(context, cls);
          },
        );
      }
    );
  }

  Widget _buildClassItem(BuildContext context, ClassModel cls) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.neonPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.event, color: AppColors.neonPurple),
        ),
        title: Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('d MMM').format(cls.date)} • ${cls.startTime} • ${cls.location}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to Class Detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentClassDetailScreen(classData: cls), // Removed prefix
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsTab() {
    return const Center(child: Text("Sin reseñas aún", style: TextStyle(color: Colors.grey)));
  }

  Widget _buildVideosTab() {
    return const Center(child: Text("Sin videos publicados", style: TextStyle(color: Colors.grey)));
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
