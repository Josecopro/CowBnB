import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _conversationsSub;
  StreamSubscription? _notificationsSub;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];
  List<AppNotificationData> _notifications = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _conversationsSub = _chatService.conversationsStream().listen((convos) {
      if (!mounted) return;
      setState(() {
        _conversations = convos;
        _filteredConversations = _filterConversations(convos, _searchQuery);
        _loading = false;
      });
    });
    _notificationsSub = _notificationService.notificationsStream().listen((notifs) {
      if (!mounted) return;
      setState(() => _notifications = notifs);
    });
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _notificationsSub?.cancel();
    searchController.dispose();
    super.dispose();
  }

  List<ChatConversation> _filterConversations(List<ChatConversation> convos, String query) {
    if (query.isEmpty) return convos;
    final q = query.toLowerCase();
    return convos.where((c) {
      return c.listingTitle.toLowerCase().contains(q);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filteredConversations = _filterConversations(_conversations, value);
    });
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  int _unreadCount(ChatConversation convo) {
    final uid = _chatService.currentUserId;
    if (uid == null) return 0;
    return convo.unread[uid] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: Text(
          'Mensajes',
          style: AppTextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          NotificationBellButton(
            notifications: _notifications.map((n) => n.toLegacy()).toList(),
            onPressed: () => showNotificationsModal(
              context,
              notifications: _notifications.map((n) => n.toLegacy()).toList(),
              notificationService: _notificationService,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar conversacion',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No hay conversaciones',
                              style: AppTextStyles.headlineSmall.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Las conversaciones con propietarios\nde tus reservas aparecerán aquí.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final convo = _filteredConversations[index];
                          final unread = _unreadCount(convo);
                          return GestureDetector(
                            onTap: () {
                              context.push('/chat?id=${convo.id}&title=${Uri.encodeComponent(convo.listingTitle)}');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.surfaceContainer,
                                    child: Icon(Icons.person,
                                        color: AppColors.textSecondary, size: 24),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(convo.listingTitle,
                                                style: AppTextStyles.label),
                                            Text(
                                              convo.lastMessageTime > 0
                                                  ? _formatTime(convo.lastMessageTime)
                                                  : '',
                                              style: AppTextStyles.labelSmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          convo.lastMessage.isNotEmpty
                                              ? convo.lastMessage
                                              : 'Sin mensajes aún',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (unread > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: AppSpacing.sm),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemCount: _filteredConversations.length,
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(activeItem: AppNavItem.messages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/map'),
        icon: const Icon(Icons.add_comment),
        label: const Text('Nuevo chat'),
      ),
    );
  }
}
