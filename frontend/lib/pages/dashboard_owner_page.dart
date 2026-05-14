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

class DashboardOwnerPage extends StatefulWidget {
  const DashboardOwnerPage({Key? key}) : super(key: key);

  @override
  State<DashboardOwnerPage> createState() => _DashboardOwnerPageState();
}

class _DashboardOwnerPageState extends State<DashboardOwnerPage> {
  final List<AppNotification> notifications = const [
    AppNotification(
      title: 'Nueva consulta de arrendatario',
      description: 'Camila pregunto por disponibilidad en Tierra Verde.',
      time: 'Hace 5 min',
      icon: Icons.chat_bubble,
    ),
    AppNotification(
      title: 'Pago recibido',
      description: 'Se recibio el pago mensual de Rancho del Sur.',
      time: 'Hace 2 h',
      icon: Icons.payments,
      isRead: true,
    ),
  ];
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
      } catch (e) {}
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
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
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
                            color: Colors.white70,
                          ),
                        ),
                        Icon(Icons.trending_up,
                            color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '\$$earningsValue',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$occupancyRate% ocupacion',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Stats Grid
              (() {
                final fallbackViews = myListings.fold<int>(0, (sum, l) => sum + ((l['views'] as num?)?.toInt() ?? 0));
                final totalViews = profile?.totalViews?.toInt() ?? fallbackViews;
                final rentedListings = myListings.where((listing) {
                  final status = listing['status']?.toString().toLowerCase() ?? 'active';
                  return status == 'rented';
                }).toList();
                final renterIds = rentedListings
                    .map((listing) => listing['renterId']?.toString())
                    .where((id) => id != null && id!.isNotEmpty)
                    .toSet();
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      icon: Icons.home,
                      label: 'Propiedades',
                      value: isLoadingListings
                          ? '...'
                          : myListings.length.toString().padLeft(2, '0'),
                    ),
                    _buildStatCard(
                      icon: Icons.check_circle,
                      label: 'Reservas Activas',
                      value: rentedListings.length.toString(),
                    ),
                    _buildStatCard(
                      icon: Icons.people,
                      label: 'Arrendatarios',
                      value: renterIds.length.toString(),
                    ),
                    _buildStatCard(
                      icon: Icons.visibility,
                      label: 'Visualizaciones',
                      value: totalViews.toString(),
                    ),
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
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('Aún no tienes propiedades publicadas.'),
                )
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
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No hay reservas aún.', style: TextStyle(color: AppColors.textSecondary)),
                )
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
        color: Colors.white,
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
                errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[200]),
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
          notifications: notifications,
          onPressed: () => showNotificationsModal(
            context,
            notifications: notifications,
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
        color: AppColors.textSecondary,
        size: 18,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 20),
          ),
        ],
      ),
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
      statusColor = Colors.blue;
      status = 'Arrendado';
    } else if (statusValue == 'review') {
      statusColor = Colors.orange;
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
        color: Colors.white,
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
                    color: statusColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
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
}
