import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/optimized_network_image.dart';
import '../components/notifications_modal.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/reservation_service.dart';
import '../services/notification_service.dart';

class DashboardOwnerPage extends StatefulWidget {
  const DashboardOwnerPage({Key? key}) : super(key: key);

  @override
  State<DashboardOwnerPage> createState() => _DashboardOwnerPageState();
}

class _DashboardOwnerPageState extends State<DashboardOwnerPage> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _notificationsSub;
  List<AppNotificationData> _notifications = [];
  final AuthService authService = AuthService();
  UserProfile? profile;
  bool isLoadingProfile = true;

  bool isLoadingListings = true;
  List<dynamic> myListings = [];
  List<dynamic> myReservations = [];
  bool isLoadingReservations = true;
  num currentEarn = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadListings();
    _loadReservations();
    _notificationsSub = _notificationService.notificationsStream().listen((notifs) {
      if (!mounted) return;
      setState(() => _notifications = notifs);
    });
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    try {
      final data = await ReservationService().getOwnerReservations();
      if (!mounted) return;
      setState(() {
        myReservations = data;
        isLoadingReservations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingReservations = false);
    }
  }

  Future<void> _loadListings() async {
    try {
      final listings = await ListingService().getMyListings();
      try {
        final profile = await authService.getProfile();
        if(profile != null) currentEarn = profile.currentMonthEarnings ?? 0;
      } catch (e) {
        debugPrint('Profile load failed: $e');
      }
      if (!mounted) return;
      setState(() {
        myListings = listings;
        isLoadingListings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingListings = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    final loadedProfile = await authService.getProfile();
    if (!mounted) return;
    setState(() {
      profile = loadedProfile;
      isLoadingProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final earnedFromListings = myListings
        .where((listing) => (listing['status']?.toString().toLowerCase() ?? 'active') == 'rented')
        .fold<num>(0, (sum, listing) => sum + (listing['bookingTotal'] as num? ?? 0));
    final profileEarnings = profile?.currentMonthEarnings ?? currentEarn;
    final resolvedEarnings = profileEarnings > 0 ? profileEarnings : earnedFromListings;
    final earningsValue = resolvedEarnings.toStringAsFixed(0);
    final activeCount = myListings.where((listing) {
      final status = listing['status']?.toString().toLowerCase() ?? 'active';
      return status == 'rented';
    }).length;
    final totalCount = myListings.length;
    final occupancyRate = totalCount == 0 ? 0 : ((activeCount / totalCount) * 100).round();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Welcome Section
              Text(
                'Panel del Propietario',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${_displayName()}',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestiona tus anuncios y ganancias.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Modo Arrendatario',
                      onPressed: () => context.go('/renter'),
                      variant: ButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Crear Anuncio',
                      onPressed: () => context.go('/create-listing'),
                      variant: ButtonVariant.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Revenue Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ingresos Mensuales',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.onDark.withValues(alpha: 0.8),
                          ),
                        ),
                        Icon(Icons.trending_up,
                            color: AppColors.onDark.withValues(alpha: 0.8),
                            size: 20),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '\$$earningsValue',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$occupancyRate% ocupacion',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onDark.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Primary metric row (single hero metric, secondary in dividers)
              (() {
                final fallbackViews = myListings.fold<int>(0, (sum, l) => sum + ((l['views'] as num?)?.toInt() ?? 0));
                final totalViews = profile?.totalViews?.toInt() ?? fallbackViews;
                final rentedListings = myListings.where((listing) {
                  final status = listing['status']?.toString().toLowerCase() ?? 'active';
                  return status == 'rented';
                }).toList();
                final renterIds = rentedListings
                    .map((listing) => listing['renterId']?.toString())
                    .where((id) => id != null && id.isNotEmpty)
                    .toSet();
                return Column(
                  children: [
                    // Primary metric
                    _buildPrimaryMetric(
                      label: 'Propiedades publicadas',
                      value: isLoadingListings
                          ? '...'
                          : myListings.length.toString().padLeft(2, '0'),
                      icon: Icons.landscape,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Secondary metrics in a row, dividers (no card chrome)
                    _buildMetricRow([
                      _MetricSpec(
                        label: 'Reservas',
                        value: rentedListings.length.toString(),
                      ),
                      _MetricSpec(
                        label: 'Arrendatarios',
                        value: renterIds.length.toString(),
                      ),
                      _MetricSpec(
                        label: 'Visitas',
                        value: totalViews.toString(),
                      ),
                    ]),
                  ],
                );
              })(),

              const SizedBox(height: AppSpacing.lg),

              // My Properties Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Propiedades',
                    style: AppTextStyles.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => context.go('/explore'),
                    child: Text(
                      'Explorar',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              if (isLoadingListings)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ))
              else if (myListings.isEmpty)
                _buildEmptyProperties()
              else
                ...myListings.map((listing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildPropertyCard(
                      listing: listing as Map<String, dynamic>,
                    ),
                  );
                }),

              const SizedBox(height: AppSpacing.lg),

              // Reservations Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reservas Recibidas',
                    style: AppTextStyles.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (isLoadingReservations)
                const Center(child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ))
              else if (myReservations.isEmpty)
                _buildEmptyReservations()
              else
                ...myReservations.map((res) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildOwnerReservationCard(res as Map<String, dynamic>),
                  );
                }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerReservationCard(Map<String, dynamic> reservation) {
    final title = reservation['listingTitle']?.toString() ?? 'Sin título';
    final renterName = reservation['renterName']?.toString() ?? 'Arrendatario';
    final image = reservation['listingImage']?.toString() ?? 'https://placehold.co/400x300.png';
    final statusValue = reservation['status']?.toString().toLowerCase() ?? 'confirmed';
    final total = reservation['total'] ?? 0;
    final months = reservation['months'] ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.network(image, width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppColors.surfaceSunken),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('$renterName • $months mes(es)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('\$$total', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  if (statusValue == 'confirmed')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          try {
                            await ReservationService().updateStatus(reservation['id'].toString(), 'cancelled');
                            _loadReservations();
                          } catch (_) {}
                        },
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.error, fontSize: 12)),
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
          notifications: _notifications.map((n) => n.toLegacy()).toList(),
          onPressed: () => showNotificationsModal(
            context,
            notifications: _notifications,
            notificationService: _notificationService,
          ),
        ),
        PopupMenuButton<String>(
          icon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildProfileAvatar(),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'logout', child: Text('Cerrar Sesión')),
          ],
        ),
      ],
    );
  }

  String _displayName() {
    if (isLoadingProfile) return '...';
    final name = profile?.displayName?.trim();
    return name == null || name.isEmpty ? 'Usuario' : name;
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.surfaceContainer,
      child: Icon(
        Icons.person,
        color: AppColors.inkMuted,
        size: 18,
      ),
    );
  }

  Widget _buildPrimaryMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.headline.copyWith(fontSize: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(List<_MetricSpec> metrics) {
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 36,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metrics[i].label, style: AppTextStyles.labelSmall),
                const SizedBox(height: 4),
                Text(
                  metrics[i].value,
                  style: AppTextStyles.title,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPropertyCard({
    required Map<String, dynamic> listing,
  }) {
    final title = listing['title']?.toString() ?? 'Sin título';

    String locStr = 'Ubicación desconocida';
    if (listing['location'] is Map) {
      final city = listing['location']['city'];
      final country = listing['location']['country'];
      if (city != null && country != null)
        locStr = '$city, $country';
    } else if (listing['location'] != null) {
      locStr = listing['location'].toString();
    }

    final size = listing['size']?.toString() ?? '0';
    final location = '$locStr • $size Hectáreas';

    final images = listing['images'] as List<dynamic>?;
    final image = (images != null && images.isNotEmpty)
        ? images.first.toString()
        : 'https://placehold.co/1000x800?text=No+Image';

    final priceVal = listing['price']?.toString() ?? '0';
    final earnings = '\$$priceVal/mes';
    final statusValue = listing['status']?.toString().toLowerCase() ?? 'active';
    Color statusColor = AppColors.success;
    String status = 'Activo';
    if (statusValue == 'rented') {
      statusColor = AppColors.info;
      status = 'Arrendado';
    } else if (statusValue == 'review') {
      statusColor = AppColors.warning;
      status = 'En Revisi\u00f3n';
    }

    return GestureDetector(
      onTap: () async {
        final result = await context.push('/listing', extra: listing);
        if (result == true) {
          await _loadListings();
        }
      },
      child: Container(
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
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ingresos:',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      earnings,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (statusValue == 'review') ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ListingService().updateListingStatus(listing['id'], 'active');
                        await _loadListings();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Republicar',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEmptyProperties() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.landscape_outlined,
              size: 28, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Aún no has publicado terrenos',
              style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Publica tu primera hectarea para empezar a recibir reservas de arrendatarios calificados.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Crear Anuncio',
            onPressed: () => context.go('/create-listing'),
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReservations() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.event_note_outlined,
              size: 28, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin reservas todavía',
                    style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Las solicitudes de arrendatarios aparecerán aquí en cuanto lleguen.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSpec {
  final String label;
  final String value;
  const _MetricSpec({required this.label, required this.value});
}
