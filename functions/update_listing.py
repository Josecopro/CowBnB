import sys

content = """import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/listing_service.dart';

class ListingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ListingDetailsPage({super.key, required this.listing});

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.listing['id'] != null) {
      ListingService().recordView(widget.listing['id']);
    }

    final images = _getImagesUrls();
    if (images.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          _currentPage = (_currentPage + 1) % images.length;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<String> _getImagesUrls() {
    final imgs = widget.listing['images'];
    if (imgs == null) return [];
    if (imgs is List) {
      return imgs.map((e) => e.toString()).toList();
    }
    return [];
  }

  Widget _buildImageHeader() {
    final images = _getImagesUrls();
    
    if (images.isEmpty) {
      return Container(
        height: 350,
        width: double.infinity,
        color: AppColors.border,
        child: const Icon(Icons.terrain, size: 80, color: Colors.white),
      );
    }
    
    if (images.length == 1) {
      return AppNetworkImage(
        imageUrl: images[0],
        height: 350,
        width: double.infinity,
        fit: BoxFit.cover,
        memCacheWidth: 1280,
      );
    }

    return SizedBox(
      height: 350,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (idx) => _currentPage = idx,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return AppNetworkImage(
            imageUrl: images[index],
            height: 350,
            width: double.infinity,
            fit: BoxFit.cover,
            memCacheWidth: 1280,
          );
        },
      ),
    );
  }

  Widget _buildRating() {
    final reviewCount = widget.listing['reviewCount'];
    final rating = widget.listing['rating'];

    if (reviewCount == null || reviewCount == 0 || rating == null) {
      return Row(
        children: [
          Text('✨ Nuevo', style: AppTextStyles.label),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(rating.toString(), style: AppTextStyles.label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImageHeader(),
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/explore');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing['title']?.toString() ?? 'Sin Titulo',
                    style: AppTextStyles.headlineSmall.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            widget.listing['location']?.toString() ?? 'Cordoba, Argentina',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      _buildRating(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOverviewCard(
                          icon: Icons.landscape,
                          label: 'Tamano',
                          value: widget.listing['size'] != null ? '${widget.listing['size']} Has' : '12 Hectareas',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildOverviewCard(
                          icon: Icons.water,
                          label: 'Riego',
                          value: widget.listing['irrigation']?.toString() ?? 'Completo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOverviewCard(
                          icon: Icons.terrain,
                          label: 'Suelo',
                          value: widget.listing['soil_type']?.toString() ?? 'Premium',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildOverviewCard(
                          icon: Icons.grain,
                          label: 'Cultivos',
                          value: widget.listing['crops']?.toString() ?? 'Multiples',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Descripcion',
                    style: AppTextStyles.label.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.listing['description']?.toString() ?? 'Este terreno ofrece 12 hectareas de tierra fertil con sistemas de riego modernos. Ideal para cultivos intensivos y ganaderia sostenible.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (widget.listing['ownerId'] != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'ID del Propietario',
                      style: AppTextStyles.label.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.listing['ownerId'].toString(),
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Caracteristicas',
                    style: AppTextStyles.label.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (widget.listing['amenities'] != null && widget.listing['amenities'] is List)
                    ...((widget.listing['amenities'] as List).map((a) => _buildAmenity(a.toString())))
                  else ...[
                    _buildAmenity('Riego por goteo automatico'),
                    _buildAmenity('Caminos de acceso pavimentados'),
                    _buildAmenity('Energia electrica disponible'),
                    _buildAmenity('Certificacion organica'),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Precio por mes',
                                style: AppTextStyles.labelSmall),
                            const SizedBox(height: 4),
                            Text(
                              '\$${widget.listing['price']?.toString() ?? '1,200'}',
                              style: AppTextStyles.headline.copyWith(
                                color: AppColors.primary,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 120,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => context.go('/checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                            ),
                            child: Text(
                              'Reservar',
                              style: AppTextStyles.label
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeItem: AppNavItem.explore),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.label),
        ],
      ),
    );
  }

  Widget _buildAmenity(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
"""

with open("/home/sanma613/UProjects/CowBnB/frontend/lib/pages/listing_details_page.dart", "w") as f:
    f.write(content)

