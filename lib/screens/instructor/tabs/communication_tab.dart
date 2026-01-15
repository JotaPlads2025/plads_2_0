import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/neon_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart'; // Import Service
import '../../../../models/chat_model.dart'; // Import Models
import '../../../../models/broadcast_model.dart';
import '../../../../models/user_model.dart';
import '../../common/chat_screen.dart'; // Import Chat Screen
import 'package:uuid/uuid.dart';

class CommunicationTab extends StatefulWidget {
  const CommunicationTab({super.key});

  @override
  State<CommunicationTab> createState() => _CommunicationTabState();
}

class _CommunicationTabState extends State<CommunicationTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _subjectController = TextEditingController(); // For Broadcast Title
  final _messageController = TextEditingController(); // For Broadcast Message
  
  // State for Campaign audience
  String _selectedAudience = 'active_students'; // 'active_students', 'followers', 'interests'
  List<String> _targetInterests = []; // For 'interests'
  List<String> _availableInterests = ['Salsa', 'Bachata', 'Kizomba', 'Tango', 'Reggaeton']; // Mock/Standard disciplines

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = Provider.of<AuthService>(context).currentUser;

    if (currentUser == null) return const Center(child: Text('Cargando...'));

    return Column(
      children: [
        // Standard Tab Bar
        Container(
          color: Colors.transparent, 
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.neonGreen,
            labelColor: AppColors.neonGreen,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.inbox_outlined), text: 'Inbox'),
              Tab(icon: Icon(Icons.forum_outlined), text: 'Foros'),
              Tab(icon: Icon(Icons.campaign_outlined), text: 'Comunidad'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInbox(currentUser.uid),
              _buildClassForums(),
              _buildCommunityCampaigns(context, currentUser.uid, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInbox(String userId) {
    return StreamBuilder<List<ChatModel>>(
      stream: Provider.of<FirestoreService>(context).getUserChats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final chats = snapshot.data!;
        
        if (chats.isEmpty) {
          return _buildEmptyState(Icons.inbox, 'Tu bandeja de entrada está vacía');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];
            // Determine other participant name
            String otherId = chat.participants.firstWhere((p) => p != userId, orElse: () => '');
            
            // Handle self-chat (if I am messaging myself)
            if (otherId.isEmpty) {
               otherId = userId; 
            }
            
            final otherName = chat.participantNames[otherId] ?? 'Usuario';
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.neonBlue,
                child: Text(otherName.isNotEmpty ? otherName[0] : '?', style: const TextStyle(color: Colors.white)),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _formatTime(chat.lastMessageTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(chatId: chat.id, otherUserName: otherName, otherUserId: otherId)
                ));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildClassForums() {
     return _buildEmptyState(Icons.forum_outlined, 'No hay foros activos');
  }

  Widget _buildCommunityCampaigns(BuildContext context, String userId, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enviar Anuncio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Llega a tu audiencia ideal con mensajes dirigidos.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          
          // Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audiencia', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedAudience,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                  items: const [
                    DropdownMenuItem(value: 'active_students', child: Text('Alumnos Activos (En Clases)')),
                    DropdownMenuItem(value: 'followers', child: Text('Seguidores (Mis Favoritos)')),
                    DropdownMenuItem(value: 'interests', child: Text('Por Intereses (Salsa, Bachata...)')),
                  ], 
                  onChanged: (val) {
                    setState(() {
                      _selectedAudience = val!;
                      // Auto-select standard interests if selected (Mock logic, real would fetch instructor disciplines)
                      if (val == 'interests' && _targetInterests.isEmpty) {
                        _targetInterests = ['Salsa', 'Bachata']; 
                      }
                    });
                  },
                ),
                
                // Interest Tags Selector
                if (_selectedAudience == 'interests') ...[
                  const SizedBox(height: 12),
                  const Text('Intereses Objetivo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: _availableInterests.map((interest) {
                      final isSelected = _targetInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        selectedColor: AppColors.neonPurple.withOpacity(0.3),
                        checkmarkColor: AppColors.neonPurple,
                        onSelected: (selected) {
                           setState(() {
                             if (selected) {
                               _targetInterests.add(interest);
                             } else {
                               _targetInterests.remove(interest);
                             }
                           });
                        },
                      );
                    }).toList(),
                  )
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: _subjectController,
                   decoration: const InputDecoration(labelText: 'Asunto / Título', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mensaje', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _isSending 
                   ? const Center(child: CircularProgressIndicator())
                   : NeonButton(
                    text: 'Enviar Campaña', 
                    color: AppColors.neonPurple,
                    onPressed: () async {
                      if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
                         return;
                      }

                      setState(() => _isSending = true);
                      try {
                        final broadcast = BroadcastModel(
                          id: const Uuid().v4(),
                          instructorId: userId,
                          title: _subjectController.text.trim(),
                          message: _messageController.text.trim(),
                          audienceType: _selectedAudience,
                          targetInterests: _selectedAudience == 'interests' ? _targetInterests : null,
                          timestamp: DateTime.now(),
                        );

                        await Provider.of<FirestoreService>(context, listen: false).sendBroadcast(broadcast);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaña enviada con éxito 🚀')));
                          _subjectController.clear();
                          _messageController.clear();
                        }
                      } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                         if (mounted) setState(() => _isSending = false);
                      }
                    }
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
