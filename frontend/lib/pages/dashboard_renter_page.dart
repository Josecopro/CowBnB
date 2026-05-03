import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/auth_service.dart';

class DashboardRenterPage extends StatefulWidget {
  const DashboardRenterPage({Key? key}) : super(key: key);

  @override
  State<DashboardRenterPage> createState() => _DashboardRenterPageState();
}

class _DashboardRenterPageState extends State<DashboardRenterPage> {
  final List<AppNotification> notifications = const [
    AppNotification(
      title: 'Nuevo mensaje del propietario',
      description: 'Tienes una actualizacion en Rancho del Sur.',
      time: 'Hace 8 min',
      icon: Icons.message,
    ),
    AppNotification(
      title: 'Reserva confirmada',
      description: 'Tu reserva para Valle de los Girasoles fue confirmada.',
      time: 'Hace 1 h',
      icon: Icons.check_circle,
      isRead: true,
    ),
  ];
  final AuthService authService = AuthService();
  UserProfile? profile;
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
                        'Hola, ${_displayName()}',
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

              // Action Buttons
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

              // Stats Grid
              _buildStatsGrid(),

              const SizedBox(height: AppSpacing.lg),

              // Bookings Section
              _buildBookingsSection(),

              const SizedBox(height: AppSpacing.lg),

              // Secondary Actions
              _buildSecondaryActions(),

              const SizedBox(height: 100),
            ],
          ),
        ),
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

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: [
        _buildStatCard(
          icon: Icons.calendar_month,
          label: 'Reservas Activas',
          value: '03',
        ),
        _buildStatCard(
          icon: Icons.favorite,
          label: 'Favoritos',
          value: '12',
        ),
        _buildStatCard(
          icon: Icons.message,
          label: 'Mensajes',
          value: '05',
        ),
        _buildStatCard(
          icon: Icons.landscape,
          label: 'Hectáreas',
          value: '45.2',
        ),
      ],
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

  Widget _buildBookingsSection() {
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
        _buildBookingCard(
          title: 'Valle de los Girasoles',
          location: 'Córdoba, Argentina • 12 Hectáreas',
          image:
              'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=1000&auto=format&fit=crop',
          status: 'Confirmado',
          dates: '15 Oct - 20 Dic',
          price: '\$1,200/mes',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBookingCard(
          title: 'Laderas del Sur',
          location: 'Mendoza, Argentina • 8 Hectáreas',
          image:
              'https://images.unsplash.com/photo-1464226184884-fa280b87c399?q=80&w=1000&auto=format&fit=crop',
          status: 'Pendiente',
          dates: '01 Nov - 15 Ene',
          price: '\$850/mes',
        ),
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
