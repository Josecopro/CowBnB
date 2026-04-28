import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/notifications_modal.dart';
import '../components/optimized_network_image.dart';
import '../components/stat_card.dart';
import '../services/cowbnb_api.dart';
import '../models/api_models.dart';

class DashboardOwnerPage extends StatefulWidget {
  const DashboardOwnerPage({Key? key}) : super(key: key);

  @override
  State<DashboardOwnerPage> createState() => _DashboardOwnerPageState();
}

class _DashboardOwnerPageState extends State<DashboardOwnerPage> {
  late final CowbnbApi _api;
  late Future<OwnerDashboardData> _dashboardFuture;
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _api = CowbnbApi();
    _dashboardFuture = _api.fetchOwnerDashboard();
    _notificationsFuture = _api.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: FutureBuilder<OwnerDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final dashboard = snapshot.data;
          final stats = dashboard?.stats;
          final properties = dashboard?.properties ?? const <Listing>[];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: AppSpacing.md),

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
                        'Hola, Carlos',
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

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                children: [
                  DashboardStatCard(
                    icon: Icons.home,
                    label: 'Propiedades',
                    value: '${stats?.propertiesCount ?? 0}',
                  ),
                  DashboardStatCard(
                    icon: Icons.check_circle,
                    label: 'Reservas Activas',
                    value: '${stats?.activeReservationsCount ?? 0}',
                  ),
                  DashboardStatCard(
                    icon: Icons.people,
                    label: 'Arrendatarios',
                    value: '${stats?.rentersCount ?? 0}',
                  ),
                  DashboardStatCard(
                    icon: Icons.visibility,
                    label: 'Visualizaciones',
                    value: '${stats?.viewsCount ?? 0}',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

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

              if (properties.isEmpty)
                Text(
                  'No hay propiedades registradas.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ...properties.map((listing) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildPropertyCard(
                      title: listing.title,
                      location: '${listing.location} • ${listing.sizeHectares ?? 0} Hectáreas',
                      image: listing.imageUrl,
                      status: 'Activo',
                      earnings: '\$${listing.priceMonthly}/mes',
                    ),
                  )),

              const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: const AppAvatar(
            radius: 16,
            imageUrl:
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1000&auto=format&fit=crop',
          ),
        ),
      ],
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
