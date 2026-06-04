import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';

class RegisterRoleSelectionPage extends StatelessWidget {
  const RegisterRoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top AppBar
            Container(
              color: AppColors.darkBg.withValues(alpha: 0.8),
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
                    '¿Que deseas hacer?',
                    style: AppTextStyles.display,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Subtitle
                  Text(
                    'Elige tu rol en la plataforma para continuar',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Option 1: Owner / Arrendar tierra
                  _buildRoleCard(
                    context,
                    icon: Icons.landscape,
                    title: 'Arrendar mi tierra',
                    description:
                        'Soy propietario y quiero rentabilizar mis tierras agricolas',
                    role: 'owner',
                    backgroundColor: AppColors.primarySoft,
                    borderColor: AppColors.primary,
                    iconColor: AppColors.primaryInk,
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
                    backgroundColor: AppColors.accentSoft,
                    borderColor: AppColors.accent,
                    iconColor: AppColors.accentHover,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Puedes cambiar tu rol despues',
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tu seleccion no es definitiva. Podras cambiar entre roles o manejar ambos desde tu perfil una vez que hayas creado tu cuenta.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.inkMuted,
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
                '© 2026 CowBnB SAS. Innovacion para el agro',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.inkMuted,
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
    required Color iconColor,
  }) {
    return Semantics(
      button: true,
      label: '$title. $description',
      child: InkWell(
        onTap: () => context.push('/register?role=$role'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
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
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
