import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/reservation_service.dart';

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

  Future<void> _openNewChatSheet() async {
    final uid = _chatService.currentUserId;
    if (uid == null) return;

    final contacts = <Map<String, String?>>[];
    try {
      final renterReservations = await ReservationService().getMyReservations();
      for (final r in renterReservations) {
        final rm = r as Map<String, dynamic>;
        if (rm['status']?.toString() == 'cancelled') continue;
        contacts.add({
          'name': rm['ownerName']?.toString(),
          'id': rm['ownerId']?.toString(),
          'listingTitle': rm['listingTitle']?.toString(),
          'listingId': rm['listingId']?.toString(),
          'listingImage': rm['listingImage']?.toString(),
          'type': 'renter',
        });
      }

      final ownerReservations = await ReservationService().getOwnerReservations();
      for (final r in ownerReservations) {
        final rm = r as Map<String, dynamic>;
        if (rm['status']?.toString() == 'cancelled') continue;
        contacts.add({
          'name': rm['renterName']?.toString(),
          'id': rm['renterId']?.toString(),
          'listingTitle': rm['listingTitle']?.toString(),
          'listingId': rm['listingId']?.toString(),
          'listingImage': rm['listingImage']?.toString(),
          'type': 'owner',
        });
      }

      contacts.removeWhere((c) => c['id'] == null || c['id']!.isEmpty);
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewChatSheet(
        contacts: contacts,
        onContactTap: (contact) async {
          Navigator.pop(ctx);
          final otherUserId = contact['id']!;
          final listingTitle = contact['listingTitle'] ?? '';
          final listingId = contact['listingId'];

          final existingId = await _chatService.findExistingConversation(
            otherUserId: otherUserId,
            listingId: listingId,
          );
          final convoId = existingId ?? await _chatService.createConversation(
            otherUserId: otherUserId,
            listingTitle: listingTitle,
            listingId: listingId,
          );
          if (mounted) {
            context.push('/chat?id=$convoId&title=${Uri.encodeComponent(listingTitle)}');
          }
        },
      ),
    );
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
              notifications: _notifications,
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
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 28,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Aun no tienes conversaciones',
                                style: AppTextStyles.label,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Los mensajes con propietarios de tus\nreservas apareceran aqui.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final convo = _filteredConversations[index];
                          final unread = _unreadCount(convo);
                          return Semantics(
                            button: true,
                            label: 'Conversacion sobre ${convo.listingTitle}',
                            child: InkWell(
                              onTap: () {
                                context.push('/chat?id=${convo.id}&title=${Uri.encodeComponent(convo.listingTitle)}');
                              },
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.surfaceContainer,
                                      child: Icon(Icons.person,
                                          color: AppColors.inkMuted, size: 24),
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
                                                : 'Aun sin mensajes',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.inkMuted,
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
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
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
        onPressed: _openNewChatSheet,
        icon: const Icon(Icons.add_comment),
        label: const Text('Nuevo chat'),
      ),
    );
  }
}

class _NewChatSheet extends StatelessWidget {
  final List<Map<String, String?>> contacts;
  final void Function(Map<String, String?>) onContactTap;

  const _NewChatSheet({
    required this.contacts,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 52,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(
                  'Nuevo mensaje',
                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (contacts.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(
                          Icons.person_add_disabled,
                          size: 28,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Aun no tienes contactos',
                        style: AppTextStyles.label,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Solo puedes chatear con personas\ncon las que tengas una reserva activa.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final name = contact['name'] ?? 'Usuario';
                  final listing = contact['listingTitle'] ?? 'Terreno';
                  final image = contact['listingImage'] ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.sm),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surfaceContainer,
                        backgroundImage: image.isNotEmpty
                            ? NetworkImage(image)
                            : null,
                        child: image.isEmpty
                            ? Icon(Icons.person, color: AppColors.inkMuted, size: 24)
                            : null,
                      ),
                      title: Text(name, style: AppTextStyles.label),
                      subtitle: Text(
                        listing,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline,
                          color: AppColors.primary, size: 20),
                      onTap: () => onContactTap(contact),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
