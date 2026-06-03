import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../services/notification_service.dart';

class AppNotification {
  const AppNotification({
    required this.title,
    required this.description,
    required this.time,
    this.isRead = false,
    this.icon = Icons.notifications,
  });

  final String title;
  final String description;
  final String time;
  final bool isRead;
  final IconData icon;
}

int unreadNotificationsCount(List<AppNotification> notifications) {
  return notifications.where((notification) => !notification.isRead).length;
}

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.notifications,
    required this.onPressed,
    this.iconColor = AppColors.primary,
  });

  final List<AppNotification> notifications;
  final VoidCallback onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final int unreadCount = unreadNotificationsCount(notifications);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications, color: iconColor),
          onPressed: onPressed,
        ),
        if (unreadCount > 0)
          Positioned(
            top: 7,
            right: 6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.darkBg, width: 1.2),
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showNotificationsModal(
  BuildContext context, {
  required List<AppNotificationData> notifications,
  NotificationService? notificationService,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bool hasNotifications = notifications.isNotEmpty;

          return Container(
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notificaciones',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      if (hasNotifications)
                        TextButton(
                          onPressed: () {
                            notificationService?.markAllAsRead();
                          },
                          child: Text(
                            'Marcar todo leído',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: hasNotifications
                      ? ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          itemBuilder: (context, index) {
                            final AppNotificationData notification =
                                notifications[index];
                            return _NotificationTile(
                              notification: notification,
                              onTap: () {
                                _handleNotificationTap(context, notification, notificationService);
                              },
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemCount: notifications.length,
                        )
                      : _buildEmptyState(),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildEmptyState() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No tienes notificaciones',
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cuando haya novedades sobre tus reservas o mensajes, apareceran aqui.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  final AppNotificationData notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final legacy = notification.toLegacy();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: legacy.isRead
              ? AppColors.surfaceContainerLowest
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: legacy.isRead ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(legacy.icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    legacy.title,
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    legacy.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    legacy.time,
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _handleNotificationTap(
  BuildContext context,
  AppNotificationData notification,
  NotificationService? notificationService,
) {
  final conversationId = notification.data['conversationId']?.toString();
  if (conversationId == null || conversationId.isEmpty) return;

  final title = notification.data['listingTitle']?.toString() ?? notification.title;
  notificationService?.markAsRead(notification.id);
  Navigator.of(context).pop();
  context.push('/chat?id=$conversationId&title=${Uri.encodeComponent(title)}');
}
