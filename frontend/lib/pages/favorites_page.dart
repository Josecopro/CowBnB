import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/cowbnb_api.dart';
import '../models/api_models.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final CowbnbApi _api;
  late Future<List<FavoriteListing>> _favoritesFuture;
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _api = CowbnbApi();
    _favoritesFuture = _api.fetchFavorites();
    _notificationsFuture = _api.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: Text(
          'Favoritos',
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
      body: FutureBuilder<List<FavoriteListing>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          final favorites = snapshot.data ?? const <FavoriteListing>[];
          return favorites.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(favorites);
        },
      ),
      bottomNavigationBar: const AppBottomNav(activeItem: AppNavItem.favorites),
    );
  }

  Widget _buildFavoritesList(List<FavoriteListing> favorites) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemBuilder: (context, index) {
        final FavoriteListing item = favorites[index];
        return GestureDetector(
          onTap: () => context.go('/listing/${item.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                  child: AppNetworkImage(
                    imageUrl: item.image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.label.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${item.location} • ${item.hectares}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.price,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: AppColors.error),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemCount: favorites.length,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No tienes favoritos guardados',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Explora terrenos y toca el corazon para guardarlos aqui.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.search),
              label: const Text('Ir a explorar'),
            ),
          ],
        ),
      ),
    );
  }

}
