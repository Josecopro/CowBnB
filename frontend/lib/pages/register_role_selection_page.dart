import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';

class RegisterRoleSelectionPage extends StatelessWidget {
  const RegisterRoleSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top AppBar
            Container(
              color: AppColors.darkBg.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: AppColors.primary, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'CowBnB',
                        style: AppTextStyles.headline.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    '¿Qué deseas hacer?',
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontSize: 36,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Subtitle
                  Text(
                    'Elige tu rol en la plataforma para continuar',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(height: AppSpacing.lg),

                  // Option 1: Owner / Arrendar tierra
                  _buildRoleCard(
                    context,
                    icon: Icons.landscape,
                    title: 'Arrendar mi tierra',
                    description:
                        'Soy propietario y quiero rentabilizar mis tierras agrícolas',
                    role: 'owner',
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    borderColor: AppColors.primary,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Option 2: Renter / Buscar tierras
                  _buildRoleCard(
                    context,
                    icon: Icons.search,
                    title: 'Buscar tierras',
                    description:
                        'Soy inquilino y busco tierras para arrendar y cultivar',
                    role: 'renter',
                    backgroundColor: AppColors.success.withOpacity(0.1),
                    borderColor: AppColors.success,
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(height: AppSpacing.lg),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Puedes cambiar tu rol después',
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tu selección no es definitiva. Podrás cambiar entre roles o manejar ambos desde tu perfil una vez que hayas creado tu cuenta.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                '© 2026 CowBnB SAS. Inovación para el agro',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String role,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () => context.push('/register?role=$role'),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                size: 40,
                color: borderColor,
              ),
            ),

            const SizedBox(width: AppSpacing.lg),

            // Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
