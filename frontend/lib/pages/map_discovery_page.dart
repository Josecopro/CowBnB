import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/listing_service.dart';
import '../services/notification_service.dart';
import 'dart:math';

class MapDiscoveryPage extends StatefulWidget {
  const MapDiscoveryPage({Key? key}) : super(key: key);

  @override
  State<MapDiscoveryPage> createState() => _MapDiscoveryPageState();
}

class _MapDiscoveryPageState extends State<MapDiscoveryPage> {
  final List<AppNotification> notifications = const [
    AppNotification(
      title: 'Nuevos terrenos en tu zona',
      description: 'Aparecieron 2 opciones con disponibilidad inmediata.',
      time: 'Hace 20 min',
      icon: Icons.travel_explore,
    ),
  ];

  List<AppNotificationData> get _notificationData {
    final now = DateTime.now().millisecondsSinceEpoch;
    return notifications.map((n) {
      return AppNotificationData(
        id: 'local-${n.title.hashCode}',
        type: 'system',
        title: n.title,
        description: n.description,
        timestamp: now,
        read: n.isRead,
        icon: n.icon,
      );
    }).toList();
  }

  List<dynamic> allListings = [];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final listings = await ListingService().getAllListings();
      final activeListings = listings.where((listing) {
        final status = listing['status']?.toString().toLowerCase();
        return status == null || status == 'active';
      }).toList();
      if (!mounted) return;
      setState(() {
        allListings = activeListings;
      });
    } catch (e) {
      debugPrint('Error loading listings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar ubicación',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkMuted,
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.inkMuted),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                ),
              ),
            ),

            // Map Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Stack(
                children: [
                  // Map Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: AppNetworkImage(
                      imageUrl:
                          'https://images.unsplash.com/photo-1586771107445-d3af255c2690?q=80&w=2832&auto=format&fit=crop',
                      height: 400,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 1280,
                    ),
                  ),

                  // Price Pins from real listings only
                  ...allListings.take(4).map((listing) {
                    final random = Random(listing.hashCode);
                    // Random positions between 40 and 200 for top/bottom, 40 and 200 for left/right
                    final top = 40.0 + random.nextInt(160);
                    final left = 40.0 + random.nextInt(160);
                    final price = '\$${listing['price'] ?? 0}';

                    return Positioned(
                      top: top,
                      left: left,
                      child: _buildePricePin(price,
                          highlighted: random.nextBool()),
                    );
                  }),

                  // Control Buttons (Top Right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMapControlButton(Icons.layers),
                        const SizedBox(height: AppSpacing.sm),
                        _buildMapControlButton(Icons.my_location),
                      ],
                    ),
                  ),

                  // Filter Button (Bottom Center)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_list, color: Colors.white),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Resaltar terrenos disponibles',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Recommended Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recomendado para ti',
                            style: AppTextStyles.headlineSmall,
                          ),
                          Text(
                            'Basado en tu actividad',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Ver todas',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Recommended Cards Horizontal Scroll
            SizedBox(
              height: 330,
              child: allListings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined,
                                size: 32, color: AppColors.inkMuted),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Aun no hay terrenos para mostrar',
                              style: AppTextStyles.label,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Vuelve pronto: seguimos publicando nuevas hectareas.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        for (final listing in allListings)
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.md),
                            child: _buildListingCard(
                              listing: listing as Map<String, dynamic>,
                            ),
                          ),
                      ],
                    ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      label: 'Rendimiento local',
                      value: '94%',
                      subtitle: '+2.4%',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatBox(
                      label: 'Calidad del suelo',
                      value: 'Premium',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeItem: AppNavItem.explore),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.eco, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'CowBnB',
            style: AppTextStyles.headline.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        NotificationBellButton(
          notifications: notifications,
          onPressed: () => showNotificationsModal(
            context,
            notifications: _notificationData,
          ),
        ),
      ],
    );
  }

  Widget _buildePricePin(String price, {bool highlighted = false}) {
    return Semantics(
      button: true,
      label: 'Terreno desde $price al mes',
      child: GestureDetector(
        onTap: () => context.go('/listing'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border:
                highlighted ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Text(
            price,
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }

  Widget _buildListingCard({
    required Map<String, dynamic> listing,
  }) {
    final title = listing['title']?.toString() ?? 'Sin título';

    String location = 'Ubicación no especificada';
    if (listing['location'] is Map) {
      final city = listing['location']['city'];
      final country = listing['location']['country'];
      if (city != null && country != null) {
        location = "$city, $country";
      }
    } else if (listing['location'] != null) {
      location = listing['location'].toString();
    }

    final images = listing['images'] as List<dynamic>?;
    final image = (images != null && images.isNotEmpty)
        ? images.first.toString()
        : 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=1000&auto=format&fit=crop';

    final priceStr = listing['price']?.toString() ?? '0';
    final price = '\$$priceStr';
    final rating = 4.9; // Add real rating if available in data later
    final acres = '${listing['totalArea'] ?? '0'} hectareas';

    return GestureDetector(
      onTap: () => context.push('/listing', extra: listing),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                  child: AppNetworkImage(
                    imageUrl: image,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 860,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Mejor valor',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '/mes',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          acres,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.inkMuted,
                            fontSize: 12,
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
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 20,
                  color: color,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTextStyles.label.copyWith(
                    color: color,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
