import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import 'package:go_router/go_router.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController searchController = TextEditingController();

  final List<AppNotification> notifications = const [
    AppNotification(
      title: 'Nuevo mensaje',
      description: 'Camila te envio un nuevo mensaje sobre Pradera Norte.',
      time: 'Hace 3 min',
      icon: Icons.message,
    ),
  ];

  final List<_ConversationItem> conversations = const [
    _ConversationItem(
      name: 'Camila Rios',
      listing: 'Pradera Norte',
      message: 'Perfecto, puedo visitar el terreno este viernes?',
      time: '10:42',
      unreadCount: 2,
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop',
    ),
    _ConversationItem(
      name: 'Martin Lopez',
      listing: 'Laderas del Sur',
      message: 'Ya subi los documentos para la reserva.',
      time: 'Ayer',
      unreadCount: 0,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=600&auto=format&fit=crop',
    ),
    _ConversationItem(
      name: 'Valentina Cruz',
      listing: 'Campo Santa Elena',
      message: 'Me gustaria confirmar disponibilidad para mayo.',
      time: 'Ayer',
      unreadCount: 1,
      avatarUrl:
          'https://images.unsplash.com/photo-1546961329-78bef0414d7c?q=80&w=600&auto=format&fit=crop',
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            notifications: notifications,
            onPressed: () => showNotificationsModal(
              context,
              notifications: notifications,
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemBuilder: (context, index) {
                final _ConversationItem item = conversations[index];
                return GestureDetector(
                  onTap: () {
                    context.push('/chat?id=conv_${index}&title=${Uri.encodeComponent(item.name)}');
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      margin: const EdgeInsets.only(
                                          left: AppSpacing.sm),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${item.unreadCount}',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
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
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemCount: conversations.length,
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

class _ConversationItem {
  const _ConversationItem({
    required this.name,
    required this.listing,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.avatarUrl,
  });

  final String name;
  final String listing;
  final String message;
  final String time;
  final int unreadCount;
  final String avatarUrl;
}
