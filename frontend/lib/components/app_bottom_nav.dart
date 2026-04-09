import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';

enum AppNavItem {
  explore,
  favorites,
  messages,
  profile,
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.activeItem,
  });

  final AppNavItem activeItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              item: AppNavItem.explore,
              icon: Icons.search,
              label: 'Explorar',
              route: '/explore',
            ),
            _buildNavItem(
              context,
              item: AppNavItem.favorites,
              icon: Icons.favorite,
              label: 'Favoritos',
              route: '/favorites',
            ),
            _buildNavItem(
              context,
              item: AppNavItem.messages,
              icon: Icons.message,
              label: 'Mensajes',
              route: '/messages',
            ),
            _buildNavItem(
              context,
              item: AppNavItem.profile,
              icon: Icons.person,
              label: 'Perfil',
              route: '/renter',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required AppNavItem item,
    required IconData icon,
    required String label,
    required String route,
  }) {
    final bool isActive = item == activeItem;

    return GestureDetector(
      onTap: () {
        // Avoid re-entrant navigation operations that can trigger
        // navigator lock assertions when taps happen during transitions.
        if (isActive) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go(route);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.success : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.success : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
