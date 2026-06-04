import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/listing_service.dart';
import '../services/notification_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController searchController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _notificationsSub;
  Timer? _searchDebounce;
  List<AppNotificationData> _notifications = [];

  bool isLoading = true;
  bool hasError = false;
  List<dynamic> allListings = [];
  List<dynamic> filteredListings = [];

  // Filter states
  bool isAvailable = false;
  bool hasIrrigation = false;
  bool under10Ha = false;
  bool hasPower = false;
  bool hasGoodPasture = false; // NDVI > 0.5


  @override
  void initState() {
    super.initState();
    _loadListings();
    _notificationsSub = _notificationService.notificationsStream().listen((notifs) {
      if (!mounted) return;
      setState(() => _notifications = notifs);
    });
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    try {
      final listings = await ListingService().getAllListings();
      if (!mounted) return;
      setState(() {
        allListings = listings;
        filteredListings = listings;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  bool get _hasActiveFilters =>
      isAvailable ||
      hasIrrigation ||
      under10Ha ||
      hasPower ||
      hasGoodPasture ||
      searchController.text.isNotEmpty;

  void _clearFilters() {
    setState(() {
      isAvailable = false;
      hasIrrigation = false;
      under10Ha = false;
      hasPower = false;
      hasGoodPasture = false;
      searchController.clear();
    });
    _applyFilters();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _applyFilters);
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();

    setState(() {
       filteredListings = allListings.where((listing) {
         final title = (listing['title']?.toString() ?? '').toLowerCase();
         final description = (listing['description']?.toString() ?? '').toLowerCase();
         final locationInfo = listing['location'];
         
         String location = '';
         if (locationInfo is Map) {
           location = '${locationInfo['city'] ?? ''} ${locationInfo['country'] ?? ''}'.toLowerCase();
         } else if (locationInfo != null) {
           location = locationInfo.toString().toLowerCase();
         }

         // Text query
         bool matchesQuery = query.isEmpty || title.contains(query) || description.contains(query) || location.contains(query);

         // Properties checks
         final amenitiesList = listing['amenities'];
         final featuresList = listing['features'];
         final sizeVal = listing['size'];

         bool amenitiesHas(String keyword) {
             if (amenitiesList is List) {
                 return amenitiesList.any((e) => e.toString().toLowerCase().contains(keyword));
             }
             if (featuresList is List) {
                 return featuresList.any((e) => e.toString().toLowerCase().contains(keyword));
             }
             return false;
         }

         final statusValue = listing['status']?.toString().toLowerCase();
         bool matchesAvailable = !isAvailable || statusValue == null || statusValue == 'active';
         if (!matchesAvailable) return false;
         
         // Riego (Irrigation)
         bool matchesIrrigation = !hasIrrigation || (listing['irrigation']?.toString().toLowerCase() == 'completo') || amenitiesHas('riego');

         // Menos de 10 ha (Size < 10)
         bool matchesSize = !under10Ha;
         if (under10Ha && sizeVal != null) {
             double sz = 0.0;
             if (sizeVal is num) {
                 sz = sizeVal.toDouble();
             } else {
                 sz = double.tryParse(sizeVal.toString()) ?? 100.0;
             }
             matchesSize = sz < 10.0;
         }

         // Energia (Power)
         bool matchesPower = !hasPower || amenitiesHas('energia') || amenitiesHas('eléctrica') || amenitiesHas('electrica');

         // Buen pasto (NDVI > 0.5)
         bool matchesPasture = !hasGoodPasture || (listing['ndviDetectado'] != null && (listing['ndviDetectado'] as num) > 0.5);

         return matchesQuery && matchesAvailable && matchesIrrigation && matchesSize && matchesPower && matchesPasture;
       }).toList();
    });
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
            notifications: _notifications.map((n) => n.toLegacy()).toList(),
            onPressed: () => showNotificationsModal(
              context,
              notifications: _notifications.map((n) => n.toLegacy()).toList(),
              notificationService: _notificationService,
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
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar por ciudad, precio o caracteristica',
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
              const SizedBox(height: AppSpacing.md),
               Wrap(
                 spacing: AppSpacing.sm,
                 runSpacing: AppSpacing.sm,
                 children: [
                   _FilterChip(
                     label: 'Disponibles',
                     icon: Icons.bolt,
                     isSelected: isAvailable,
                     onTap: () {
                       setState(() => isAvailable = !isAvailable);
                       _applyFilters();
                     },
                   ),
                   _FilterChip(
                     label: 'Con riego',
                     icon: Icons.water_drop,
                     isSelected: hasIrrigation,
                     onTap: () {
                       setState(() => hasIrrigation = !hasIrrigation);
                       _applyFilters();
                     },
                   ),
                   _FilterChip(
                     label: 'Menos de 10 ha',
                     icon: Icons.square_foot,
                     isSelected: under10Ha,
                     onTap: () {
                       setState(() => under10Ha = !under10Ha);
                       _applyFilters();
                     },
                   ),
                   _FilterChip(
                     label: 'Con energia',
                     icon: Icons.electric_bolt,
                     isSelected: hasPower,
                     onTap: () {
                       setState(() => hasPower = !hasPower);
                       _applyFilters();
                     },
                   ),
                   _FilterChip(
                     label: 'Buen pasto',
                     icon: Icons.grass,
                     isSelected: hasGoodPasture,
                     onTap: () {
                       setState(() => hasGoodPasture = !hasGoodPasture);
                       _applyFilters();
                     },
                   ),
                   if (_hasActiveFilters)
                     _FilterChip(
                       label: 'Limpiar filtros',
                       icon: Icons.close,
                       isSelected: false,
                       onTap: _clearFilters,
                     ),
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
              else if (hasError)
                _buildErrorState()
              else if (filteredListings.isEmpty)
                _buildEmptyState()
              else
                ...filteredListings.map((listing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildExploreCard(
                      listing: listing as Map<String, dynamic>,
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
    required Map<String, dynamic> listing,
  }) {
    final title = listing['title']?.toString() ?? 'Terreno sin titulo';

    String location = 'Ubicación por confirmar';
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
        : '';

     final priceVal = listing['price']?.toString() ?? '0';
     final price = '\$$priceVal/mes';
     final ndviValue = listing['ndviDetectado'];
     final ndviLabel = _ndviLabel(ndviValue);
     final ndviColor = _ndviColor(ndviValue);

    return Semantics(
      button: true,
      label: '$title. $location. $price. ${ndviLabel.label}.',
      child: InkWell(
        onTap: () => context.push('/listing', extra: listing),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                        _NdviBadge(label: ndviLabel.label, color: ndviColor, icon: ndviLabel.icon),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      location,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.inkMuted,
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
      ),
    );
  }

  _NdviResult _ndviLabel(dynamic ndviValue) {
    if (ndviValue == null) {
      return const _NdviResult(label: 'Sin NDVI', icon: Icons.help_outline);
    }
    final num? v = ndviValue is num ? ndviValue : num.tryParse(ndviValue.toString());
    if (v == null) {
      return const _NdviResult(label: 'Sin NDVI', icon: Icons.help_outline);
    }
    if (v >= 0.6) return const _NdviResult(label: 'Pasto vigoroso', icon: Icons.eco);
    if (v >= 0.4) return const _NdviResult(label: 'Pasto regular', icon: Icons.spa);
    return const _NdviResult(label: 'Pasto bajo', icon: Icons.grass);
  }

  Color _ndviColor(dynamic ndviValue) {
    if (ndviValue == null) return AppColors.inkMuted;
    final num? v = ndviValue is num ? ndviValue : num.tryParse(ndviValue.toString());
    if (v == null) return AppColors.inkMuted;
    if (v >= 0.6) return AppColors.success;
    if (v >= 0.4) return AppColors.warning;
    return AppColors.danger;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_off, size: 28, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            _hasActiveFilters
                ? 'Sin resultados con esos filtros'
                : 'Aun no hay terrenos publicados',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _hasActiveFilters
                ? 'Prueba quitar uno de los filtros para ver mas opciones.'
                : 'Vuelve pronto: los propietarios publican nuevas hectareas cada semana.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off, size: 28, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('No pudimos cargar los terrenos',
              style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Revisa tu conexion e intenta de nuevo.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                isLoading = true;
                hasError = false;
              });
              _loadListings();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? AppColors.onPrimary : AppColors.inkMuted;
    final bg = isSelected ? AppColors.primary : AppColors.surfaceContainer;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NdviResult {
  final String label;
  final IconData icon;
  const _NdviResult({required this.label, required this.icon});
}

class _NdviBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _NdviBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
