import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/cowbnb_api.dart';
import '../models/api_models.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController searchController = TextEditingController();

  late final CowbnbApi _api;
  late Future<ExploreData> _exploreFuture;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _api = CowbnbApi();
    _exploreFuture = _api.fetchExplore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: Text(
          'Explorar',
          style: AppTextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          FutureBuilder<ExploreData>(
            future: _exploreFuture,
            builder: (context, snapshot) {
              final notifications = snapshot.data?.notifications ?? const <AppNotification>[];
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
      body: FutureBuilder<ExploreData>(
        future: _exploreFuture,
        builder: (context, snapshot) {
          final listings = snapshot.data?.listings ?? const <Listing>[];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por ciudad, precio o caracteristica',
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
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: const [
                      _FilterChip(label: 'Disponibles ahora', icon: Icons.bolt),
                      _FilterChip(label: 'Con riego', icon: Icons.water_drop),
                      _FilterChip(label: 'Menos de 10 ha', icon: Icons.square_foot),
                      _FilterChip(label: 'Con energia', icon: Icons.electric_bolt),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Terrenos destacados', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  if (listings.isEmpty)
                    Text(
                      'No hay terrenos disponibles por ahora.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ...listings.map((listing) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildExploreCard(
                          title: listing.title,
                          location: listing.location,
                          price: '\$${listing.priceMonthly}/mes',
                          score: listing.ndviScore != null
                              ? 'NDVI ${listing.ndviScore}'
                              : 'NDVI --',
                          image: listing.imageUrl,
                          onTap: () => context.go('/listing/${listing.id}'),
                        ),
                      )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(activeItem: AppNavItem.explore),
    );
  }

  Widget _buildExploreCard({
    required String title,
    required String location,
    required String price,
    required String score,
    required String image,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                imageUrl: image,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                memCacheWidth: 800,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.label.copyWith(fontSize: 16),
                        ),
                      ),
                      Text(
                        score,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    location,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    price,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
