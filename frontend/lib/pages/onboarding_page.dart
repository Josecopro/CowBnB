import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/optimized_network_image.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation
            _buildAppBar(context),

            // Hero Section
            SizedBox(
              height: 500,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  AppNetworkImage(
                    imageUrl:
                        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=2832&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    memCacheWidth: 1280,
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.darkBg.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Floating Card
                  Positioned(
                    bottom: 32,
                    left: 24,
                    right: 24,
                    child: _buildFeaturedCard(),
                  ),
                ],
              ),
            ),

            // Content Section
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'AGRO-INVERSION 2.0',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    'El futuro de la tierra fertil.',
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontSize: 40,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    'Reserva, gestiona y escala tus proyectos agricolas con CowBnB. Descubre terrenos de alto rendimiento seleccionados por agronomos digitales.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Cómo funciona',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sigue estos pasos rápidos para comenzar a buscar o arrendar tierras.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildFlowStep(
                    step: '1',
                    title: 'Elige tu objetivo',
                    description:
                        'Decide si quieres arrendar tu tierra o buscar terrenos disponibles.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFlowStep(
                    step: '2',
                    title: 'Regístrate rápido',
                    description:
                        'Crea una cuenta y completa tu perfil para obtener resultados personalizados.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFlowStep(
                    step: '3',
                    title: 'Comienza a operar',
                    description:
                        'Publica tu oferta o busca tu próximo terreno y gestiona todo desde la app.',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Features
                  _buildFeatureItem(
                    icon: Icons.search,
                    title: 'Descubrimiento inteligente',
                    description:
                        'Filtra por composicion del suelo, cercania al agua y datos climaticos.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _buildFeatureItem(
                    icon: Icons.calendar_today,
                    title: 'Reservas sin friccion',
                    description:
                        'Asegura arriendos de tierra en minutos con plantillas legales integradas.',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/register-role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Comenzar',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Pagination & Skip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Omitir introduccion',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Soporte',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Idioma',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBg.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.eco, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terreno destacado',
                      style: AppTextStyles.labelSmall,
                    ),
                    Text(
                      'La pradera esmeralda',
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Descubre 45 hectareas de tierra premium para pastoreo con sistemas de riego sostenibles.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Certificacion organica',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Derechos de agua',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: AppTextStyles.label.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
