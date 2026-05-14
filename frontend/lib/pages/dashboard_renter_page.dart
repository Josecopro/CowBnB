import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/notifications_modal.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/reservation_service.dart';

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
  List<dynamic> reservations = [];
  bool isLoadingReservations = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final data = await ReservationService().getMyReservations();
      if (!mounted) return;
      setState(() {
        reservations = data;
        isLoadingReservations = false;
      });
    } catch (e) {
      debugPrint('Error loading reservations: $e');
      if (!mounted) return;
      setState(() => isLoadingReservations = false);
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

  Widget _buildStatsGrid() {
    final reservationCount = reservations.length.toString();
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
          value: reservationCount,
        ),
        _buildStatCard(
          icon: Icons.favorite,
          label: 'Favoritos',
          value: '0',
        ),
        _buildStatCard(
          icon: Icons.message,
          label: 'Mensajes',
          value: '0',
        ),
        _buildStatCard(
          icon: Icons.landscape,
          label: 'Hectáreas',
          value: '0',
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
              onPressed: () => context.go('/explore'),
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
        if (reservations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('No hay reservas disponibles',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...reservations.map((res) {
            return Column(
              children: [
                _buildBookingCard(
                  reservation: res as Map<String, dynamic>,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildBookingCard({
    required Map<String, dynamic> reservation,
  }) {
    final title = reservation['listingTitle']?.toString() ?? 'Sin título';
    final image = reservation['listingImage']?.toString() ?? 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=1000&auto=format&fit=crop';

    final statusValue = reservation['status']?.toString().toLowerCase() ?? 'confirmed';
    String statusText;
    Color statusColor;
    switch (statusValue) {
      case 'pending':
        statusText = 'Pendiente';
        statusColor = AppColors.warning;
        break;
      case 'confirmed':
        statusText = 'Confirmado';
        statusColor = AppColors.success;
        break;
      case 'active':
        statusText = 'Activo';
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusText = 'Completado';
        statusColor = AppColors.textSecondary;
        break;
      case 'cancelled':
        statusText = 'Cancelado';
        statusColor = AppColors.error;
        break;
      default:
        statusText = statusValue;
        statusColor = AppColors.textSecondary;
    }

    final dates = _formatDateRange(reservation['startDate'], reservation['endDate']);
    final price = '\$${reservation['monthlyPrice'] ?? 0}/mes';
    final months = reservation['months'] ?? 1;
    final total = reservation['total'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/listing', extra: {'id': reservation['listingId']}),
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
              child: Image.network(
                image,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$months mes(es) • Total: \$$total',
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
                        style: AppTextStyles.labelSmall.copyWith(fontSize: 12),
                      ),
                      Text(
                        price,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (statusValue == 'confirmed' || statusValue == 'active') ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (statusValue == 'active')
                          TextButton(
                            onPressed: () async {
                              try {
                                await ReservationService().updateStatus(
                                  reservation['id'].toString(),
                                  'completed',
                                );
                                _loadReservations();
                              } catch (_) {}
                            },
                            child: const Text('Finalizar', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                          ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            try {
                              await ReservationService().updateStatus(
                                reservation['id'].toString(),
                                'cancelled',
                              );
                              _loadReservations();
                            } catch (_) {}
                          },
                          child: const Text('Cancelar', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                      ],
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

  String _formatDateRange(dynamic start, dynamic end) {
    final startDate = _parseDate(start);
    final endDate = _parseDate(end);
    if (startDate == null || endDate == null) return 'Fechas por confirmar';
    return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
