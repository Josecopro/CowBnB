import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import 'package:go_router/go_router.dart';
import '../services/cowbnb_api.dart';
import '../models/api_models.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController searchController = TextEditingController();

  late final CowbnbApi _api;
  late Future<List<AppNotification>> _notificationsFuture;
  late Future<List<ConversationItem>> _conversationsFuture;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _api = CowbnbApi();
    _notificationsFuture = _api.fetchNotifications();
    _conversationsFuture = _api.fetchConversations();
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
          FutureBuilder<List<AppNotification>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? const <AppNotification>[];
              return NotificationBellButton(
                notifications: notifications,
                onPressed: () => showNotificationsModal(
                  context,
                  notifications: notifications,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: searchController,
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
            child: FutureBuilder<List<ConversationItem>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                final conversations = snapshot.data ?? const <ConversationItem>[];
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final ConversationItem item = conversations[index];
                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Abriendo chat con ${item.name}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
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
                            AppAvatar(
                              radius: 24,
                              imageUrl: item.avatarUrl,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item.name, style: AppTextStyles.label),
                                      Text(
                                        item.time,
                                        style: AppTextStyles.labelSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.listing,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.message,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      if (item.unreadCount > 0)
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
                                            '${item.unreadCount}',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemCount: conversations.length,
                );
              },
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

