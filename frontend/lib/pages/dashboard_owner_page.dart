import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/notifications_modal.dart';
import '../components/optimized_network_image.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final listings = await ListingService().getMyListings();
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
                      '\$5,850',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '+12% vs mes anterior',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Stats Grid
              GridView.count(
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
                    value: '02',
                  ),
                  _buildStatCard(
                    icon: Icons.people,
                    label: 'Arrendatarios',
                    value: '08',
                  ),
                  _buildStatCard(
                    icon: Icons.visibility,
                    label: 'Visualizaciones',
                    value: '342',
                  ),
                ],
              ),

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
                  final locationAndSize = '$locStr • $size Hectáreas';

                  final images = listing['images'] as List<dynamic>?;
                  final image = (images != null && images.isNotEmpty)
                      ? images.first.toString()
                      : 'https://placehold.co/1000x800?text=No+Image';

                  final priceVal = listing['price']?.toString() ?? '0';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildPropertyCard(
                      title: title,
                      location: locationAndSize,
                      image: image,
                      status: 'Activo',
                      earnings: '\$$priceVal/mes',
                    ),
                  );
                }),

              const SizedBox(height: 100),
            ],
          ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildProfileAvatar(),
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
    required String title,
    required String location,
    required String image,
    required String status,
    required String earnings,
  }) {
    return Container(
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
                    color: AppColors.success.withOpacity(0.9),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
