import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../config/app_config.dart';
import '../services/listing_service.dart';
import '../services/api_client.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

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
  
  // Polygon coordinates for terrain boundaries
  List<List<double>> _polygonCoordinates = [];
  bool _isDrawingPolygon = false;
  LatLng? _lastTappedPoint;
  final List<Marker> _markers = [];
  final List<Polygon> _polygons = [];

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

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingPolygon = !_isDrawingPolygon;
      if (!_isDrawingPolygon && _polygonCoordinates.length >= 3) {
        // Close the polygon when finishing
        if (_polygonCoordinates.first != _polygonCoordinates.last) {
          _polygonCoordinates.add(_polygonCoordinates.first);
        }
        // Update polygon display
        _updatePolygonDisplay();
      } else if (_isDrawingPolygon) {
        // Reset when starting to draw
        _polygonCoordinates = [];
        _markers.clear();
        _polygons.clear();
        _lastTappedPoint = null;
      }
    });
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    if (!_isDrawingPolygon) return;

    setState(() {
      _polygonCoordinates.add([latLng.longitude, latLng.latitude]);
      _markers.add(
        Marker(
          point: latLng,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 30,
          ),
        ),
      );
      _lastTappedPoint = latLng;
      
      // Update polygon display if we have at least 2 points
      if (_polygonCoordinates.length >= 2) {
        _updatePolygonDisplay();
      }
    });
  }

  void _updatePolygonDisplay() {
    if (_polygonCoordinates.length < 3) return;

    // Convert [lng, lat] to LatLng for polygon
    final LatLngList latLngList = _polygonCoordinates
        .map((coord) => LatLng(coord[1], coord[0]))
        .toList();

    setState(() {
      _polygons = [
        Polygon(
          points: latLngList,
          color: AppColors.success.withValues(alpha: 0.2),
          borderColor: AppColors.success,
          borderStrokeWidth: 2,
        )
      ];
    });
  }

  void _clearPolygon() {
    setState(() {
      _polygonCoordinates = [];
      _markers.clear();
      _polygons.clear();
      _lastTappedPoint = null;
    });
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

     // Validate that we have polygon coordinates if drawing was enabled
     if (_isDrawingPolygon && _polygonCoordinates.length < 3) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
             content: Text('Por favor dibuja al menos 3 puntos para delimitar el terreno')),
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
         coordenadas: _polygonCoordinates, // Add polygon coordinates
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
              color: AppColors.ink.withValues(alpha: 0.54),
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
                    label: 'Precio por Mes',
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
                        Text('Sube hasta 10 imagenes',
                            style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Toca para seleccionar archivos',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.inkMuted)),
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
                                        color: AppColors.danger,
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
         const SizedBox(height: AppSpacing.lg),
         Text('Límites del Terreno', style: AppTextStyles.headlineSmall),
         const SizedBox(height: AppSpacing.md),
         Container(
           height: 300,
           width: double.infinity,
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(AppRadius.lg),
             border: Border.all(color: AppColors.border),
           ),
           child: FlutterMap(
             options: MapOptions(
               center: LatLng(-34.6037, -58.3816), // Default to Buenos Aires
               zoom: 13,
               onTap: _isDrawingPolygon ? _handleMapTap : null,
             ),
             children: [
               TileLayer(
                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
               ),
               PolygonLayer(
                 polygons: _polygons,
               ),
               MarkerLayer(
                 markers: _markers,
               ),
             ],
           ),
         ),
         const SizedBox(height: AppSpacing.md),
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
              ElevatedButton(
                onPressed: _toggleDrawingMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDrawingPolygon
                      ? AppColors.primary
                      : AppColors.surfaceContainer,
                  foregroundColor: _isDrawingPolygon
                      ? Colors.white
                      : AppColors.inkMuted,
                ),
                child: Text(
                  _isDrawingPolygon ? 'Finalizar Dibujo' : 'Dibujar Limites',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              if (_polygonCoordinates.isNotEmpty)
                ElevatedButton(
                  onPressed: _clearPolygon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Limpiar', style: TextStyle(fontSize: 14)),
                ),
            ],
          ),
          if (_polygonCoordinates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Coordenadas: ${_polygonCoordinates.length} puntos',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.inkMuted,
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
                      isSelected ? AppColors.primary : AppColors.inkMuted,
                  size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: AppTextStyles.body),
                    Text('Categoria: ${option.category}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.inkMuted)),
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
