import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/listing_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  List<dynamic> allListings = [];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final listings = await ListingService().getAllListings();
      if (!mounted) return;
      setState(() {
        allListings = listings;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  final List<AppNotification> notifications = const [
    AppNotification(
      title: 'Nuevos terrenos cerca de ti',
      description: 'Se agregaron 3 terrenos en un radio de 30 km.',
      time: 'Hace 12 min',
      icon: Icons.travel_explore,
    ),
    AppNotification(
      title: 'Cambio en una reserva',
      description: 'Tu solicitud para Laderas del Sur fue actualizada.',
      time: 'Hace 1 h',
      icon: Icons.calendar_today,
      isRead: true,
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
          'Explorar',
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
      body: SingleChildScrollView(
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
              if (isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ))
              else if (allListings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No hay terrenos disponibles por el momento.'),
                )
              else
                ...allListings.map((listing) {
                  final title = listing['title']?.toString() ?? 'Sin título';

                  String location = 'Ubicación desconocida';
                  if (listing['location'] is Map) {
                    final city = listing['location']['city'];
                    final country = listing['location']['country'];
                    if (city != null && country != null)
                      location = '$city, $country';
                  } else if (listing['location'] != null) {
                    location = listing['location'].toString();
                  }

                  final images = listing['images'] as List<dynamic>?;
                  final image = (images != null && images.isNotEmpty)
                      ? images.first.toString()
                      : 'https://placehold.co/1200x800?text=No+Image';

                  final priceVal = listing['price']?.toString() ?? '0';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildExploreCard(
                      title: title,
                      location: location,
                      price: '\$$priceVal/mes',
                      score: 'NDVI 0.82', // Placeholder as required/unmentioned
                      image: image,
                    ),
                  );
                }),
              const SizedBox(height: 100),
            ],
          ),
        ),
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
  }) {
    return GestureDetector(
      onTap: () => context.go('/listing'),
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
