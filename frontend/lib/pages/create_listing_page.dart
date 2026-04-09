import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({Key? key}) : super(key: key);

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  int currentStep = 0;
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController sizeController;
  final Set<String> selectedFeatures = <String>{};

  static const List<_FeatureOption> _featureOptions = [
    _FeatureOption(
      label: 'Riego automático',
      category: 'Agua',
      icon: Icons.water_drop,
    ),
    _FeatureOption(
      label: 'Energía eléctrica',
      category: 'Energía',
      icon: Icons.bolt,
    ),
    _FeatureOption(
      label: 'Caminos pavimentados',
      category: 'Acceso',
      icon: Icons.alt_route,
    ),
    _FeatureOption(
      label: 'Certificación orgánica',
      category: 'Certificación',
      icon: Icons.verified,
    ),
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    priceController = TextEditingController();
    sizeController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text(
          'Crear Anuncio',
          style: AppTextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/owner');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              _buildProgressIndicator(),

              const SizedBox(height: AppSpacing.lg),

              // Step Content
              if (currentStep == 0) _buildStep1(),
              if (currentStep == 1) _buildStep2(),
              if (currentStep == 2) _buildStep3(),

              const SizedBox(height: AppSpacing.lg),

              // Navigation Buttons
              Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Atrás',
                        onPressed: () =>
                            setState(() => currentStep = currentStep - 1),
                        variant: ButtonVariant.outlined,
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: currentStep == 2 ? 'Publicar' : 'Siguiente',
                      onPressed: () {
                        if (currentStep < 2) {
                          setState(() => currentStep = currentStep + 1);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Anuncio publicado!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          context.go('/owner');
                        }
                      },
                      variant: ButtonVariant.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso ${currentStep + 1} de 3',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: (currentStep + 1) / 3,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Nombre del Terreno',
          hint: 'Ej. Rancho del Sur',
          controller: titleController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppInput(
          label: 'Descripción',
          hint: 'Describe tu terreno para que las demas personas sepan lo maravilloso que es',
          controller: descriptionController,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppInput(
                label: 'Tamaño (Hectáreas)',
                hint: '10',
                controller: sizeController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppInput(
                label: 'Precio por Día',
                hint: '\$2,500,000',
                controller: priceController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Características',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._featureOptions.map(_buildCheckboxItem),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galería de Imágenes',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image, size: 48, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sube hasta 10 imágenes',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Toca para seleccionar archivos',
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

  Widget _buildCheckboxItem(_FeatureOption option) {
    final bool isSelected = selectedFeatures.contains(option.label);

    void toggleSelection() {
      setState(() {
        if (isSelected) {
          selectedFeatures.remove(option.label);
        } else {
          selectedFeatures.add(option.label);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: InkWell(
        onTap: toggleSelection,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.category,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (_) => toggleSelection(),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureOption {
  const _FeatureOption({
    required this.label,
    required this.category,
    required this.icon,
  });

  final String label;
  final String category;
  final IconData icon;
}
