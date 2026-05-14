import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../config/app_config.dart';
import '../services/listing_service.dart';
import '../services/api_client.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({Key? key}) : super(key: key);

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  int currentStep = 0;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController maintenanceController;
  late TextEditingController sizeController;
  final Set<String> selectedFeatures = <String>{};

  static const List<_FeatureOption> _featureOptions = [
    _FeatureOption(
        label: 'Riego automático', category: 'Agua', icon: Icons.water_drop),
    _FeatureOption(
        label: 'Energía eléctrica', category: 'Energía', icon: Icons.bolt),
    _FeatureOption(
        label: 'Caminos pavimentados',
        category: 'Acceso',
        icon: Icons.alt_route),
    _FeatureOption(
        label: 'Certificación orgánica',
        category: 'Certificación',
        icon: Icons.verified),
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    priceController = TextEditingController();
    maintenanceController = TextEditingController();
    sizeController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    maintenanceController.dispose();
    sizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          _images.addAll(picked);
          if (_images.length > 10) _images = _images.sublist(0, 10);
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitListing() async {
    if (titleController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        maintenanceController.text.trim().isEmpty ||
        sizeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor completa todos los campos requeridos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient =
          ApiClient(baseUrl: AppConfig.apiBaseUrl); // Using global config
      final service = ListingService(apiClient: apiClient);

      List<Map<String, String>> imagesBase64 = [];
      for (final file in _images) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        imagesBase64.add(
            {'base64': base64Encode(bytes), 'ext': ext.isEmpty ? 'jpg' : ext});
      }

      await service.createListing(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        size: num.tryParse(sizeController.text.trim()) ?? 0,
        price: num.tryParse(priceController.text.trim()) ?? 0,
        maintenanceCost: num.tryParse(maintenanceController.text.trim()) ?? 0,
        status: "active",
        features: selectedFeatures.toList(),
        imagesBase64: imagesBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Anuncio publicado con éxito!')),
        );
        context.go('/owner');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('Crear Anuncio',
            style: AppTextStyles.headline
                .copyWith(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : context.go('/owner'),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  if (currentStep == 0) _buildStep1(),
                  if (currentStep == 1) _buildStep2(),
                  if (currentStep == 2) _buildStep3(),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (currentStep > 0)
                        Expanded(
                          child: AppButton(
                            label: 'Atrás',
                            onPressed: () => setState(() => currentStep--),
                            variant: ButtonVariant.outlined,
                          ),
                        ),
                      if (currentStep > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: currentStep == 2 ? 'Publicar' : 'Siguiente',
                          onPressed: currentStep < 2
                              ? () => setState(() => currentStep++)
                              : _submitListing,
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paso ${currentStep + 1} de 3', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: (currentStep + 1) / 3,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información Básica', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
            label: 'Nombre del Terreno',
            hint: 'Ej. Rancho del Sur',
            controller: titleController),
        const SizedBox(height: AppSpacing.md),
        AppInput(
            label: 'Descripción',
            hint: 'Describe tu terreno...',
            controller: descriptionController),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
                child: AppInput(
                    label: 'Tamaño (Hectáreas)',
                    hint: '10',
                    controller: sizeController,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: AppInput(
                    label: 'Precio por Día',
                    hint: '\$2,500,000',
                    controller: priceController,
                    keyboardType: TextInputType.number)),
          ],
        ),
          const SizedBox(height: AppSpacing.md),
          AppInput(
              label: 'Gastos de Servicios',
              hint: '\$500,000',
              controller: maintenanceController,
              keyboardType: TextInputType.number),
        ],
      );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Características', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        ..._featureOptions.map(_buildCheckboxItem),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Galería de Imágenes', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: () => _pickImages(),
          child: Container(
            width: double.infinity,
            height: _images.isNotEmpty ? null : 200,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: _images.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image,
                          size: 48, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.md),
                      Text('Sube hasta 10 imágenes',
                          style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Toca para seleccionar archivos',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < _images.length; i++)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: kIsWeb
                                  ? Image.network(_images[i].path,
                                      width: 80, height: 80, fit: BoxFit.cover)
                                  : Image.file(File(_images[i].path),
                                      width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_images.length < 10)
                        GestureDetector(
                          onTap: () => _pickImages(),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child:
                                const Icon(Icons.add, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxItem(_FeatureOption option) {
    final bool isSelected = selectedFeatures.contains(option.label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: InkWell(
        onTap: () => setState(() => isSelected
            ? selectedFeatures.remove(option.label)
            : selectedFeatures.add(option.label)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(option.icon,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: AppTextStyles.body),
                    Text('Categoría: ${option.category}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureOption {
  final String label;
  final String category;
  final IconData icon;

  const _FeatureOption(
      {required this.label, required this.category, required this.icon});
}
