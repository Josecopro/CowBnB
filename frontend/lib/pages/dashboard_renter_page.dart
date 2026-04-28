import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../components/stat_card.dart';
import '../services/cowbnb_api.dart';
import '../models/api_models.dart';

class DashboardRenterPage extends StatefulWidget {
  const DashboardRenterPage({Key? key}) : super(key: key);

  @override
  State<DashboardRenterPage> createState() => _DashboardRenterPageState();
}

class _DashboardRenterPageState extends State<DashboardRenterPage> {
  late final CowbnbApi _api;
  late Future<RenterDashboardData> _dashboardFuture;
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _api = CowbnbApi();
    _dashboardFuture = _api.fetchRenterDashboard();
    _notificationsFuture = _api.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: FutureBuilder<RenterDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final dashboard = snapshot.data;
          final stats = dashboard?.stats;
          final reservas = dashboard?.reservas ?? const <ReservaItem>[];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: AppSpacing.md),

              Text(
                'Panel del Arrendatario',
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
                        'Hola, Alejandro',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestiona tus tierras arrendadas, revisa tus mensajes.',
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
                      label: 'Modo Propietario',
                      onPressed: () => context.go('/owner'),
                      variant: ButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Buscar Tierras',
                      onPressed: () => context.go('/map'),
                      variant: ButtonVariant.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              _buildStatsGrid(stats),

              const SizedBox(height: AppSpacing.lg),

              _buildBookingsSection(reservas),

              const SizedBox(height: AppSpacing.lg),

              _buildSecondaryActions(),

              const SizedBox(height: 100),
            ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(activeItem: AppNavItem.profile),
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

  Widget _buildStatsGrid(DashboardStats? stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: [
        DashboardStatCard(
          icon: Icons.calendar_month,
          label: 'Reservas Activas',
          value: '${stats?.activeReservationsCount ?? 0}',
        ),
        DashboardStatCard(
          icon: Icons.favorite,
          label: 'Favoritos',
          value: '${stats?.favoritesCount ?? 0}',
        ),
        DashboardStatCard(
          icon: Icons.message,
          label: 'Mensajes',
          value: '${stats?.messagesCount ?? 0}',
        ),
        DashboardStatCard(
          icon: Icons.landscape,
          label: 'Hectáreas',
          value: '${stats?.hectares ?? 0}',
        ),
      ],
    );
  }

  Widget _buildBookingsSection(List<ReservaItem> reservas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis Reservas',
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
        if (reservas.isEmpty)
          Text(
            'No tienes reservas aun.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ...reservas.map((reserva) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildBookingCard(
                title: reserva.title,
                location: reserva.location,
                image: reserva.image,
                status: reserva.status,
                dates: reserva.dates,
                price: reserva.price,
                listingId: reserva.listingId,   // <-- agrega esto
              ),
            )),
      ],
    );
  }

  Widget _buildBookingCard({
      required String title,
      required String location,
      required String image,
      required String status,
      required String dates,
      required String price,
      required String listingId,   // <-- agrega esto
    }) {
    return GestureDetector(
      onTap: () => context.go('/listing/${listingId.isEmpty ? 'placeholder' : listingId}'),
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
                          style: AppTextStyles.label.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Confirmado'
                              ? AppColors.success.withOpacity(0.15)
                              : AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: status == 'Confirmado'
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
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
                        dates,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        price,
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
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.message, color: AppColors.primary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Centro de Mensajes',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tienes 2 conversaciones nuevas',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite, color: AppColors.secondary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Explorar Favoritos',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 4),
                Text(
                  'Revisa tus 12 favoritos',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
