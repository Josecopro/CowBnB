import 'package:flutter/material.dart';
import '../design_tokens.dart';

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
}
