import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../models/notification_model.dart';

export '../models/notification_model.dart';

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
  required List<AppNotification> notifications,
}) {
  final List<AppNotification> localNotifications = List<AppNotification>.from(
    notifications,
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bool hasNotifications = localNotifications.isNotEmpty;

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
                            setModalState(localNotifications.clear);
                          },
                          child: Text(
                            'Limpiar',
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
                            final AppNotification notification =
                                localNotifications[index];
                            return _NotificationTile(
                              notification: notification,
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemCount: localNotifications.length,
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
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.surfaceContainerLowest
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: notification.isRead ? AppColors.border : AppColors.primary,
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
            child: Icon(notification.icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  notification.time,
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
