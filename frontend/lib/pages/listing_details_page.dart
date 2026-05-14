import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/listing_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void _startCarouselTimer(List<String> images) {
    _carouselTimer?.cancel();
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.listing['id'] != null) {
      ListingService().recordView(widget.listing['id']);
    }

    final images = _getImagesUrls();
    if (images.length > 1) {
      _startCarouselTimer(images);
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
        onPageChanged: (idx) {
          _currentPage = idx;
          if (images.length > 1) {
            _startCarouselTimer(images);
          }
        },
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == widget.listing['ownerId'];
    final statusValue = widget.listing['status']?.toString().toLowerCase() ?? 'active';
    final isRented = statusValue == 'rented';
    final isReview = statusValue == 'review';
    final isRenter = currentUid != null && currentUid == widget.listing['renterId'];
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
                  child: isOwner ? _buildStatusChip() : GestureDetector(
                    onTap: () {
                        // TODO: Implement real favorites
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en favoritos')));
                    },
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
                    widget.listing['description']?.toString() ?? 'La propiedad no tiene una descripción detallada.',
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
                  if (widget.listing['features'] != null && widget.listing['features'] is List && (widget.listing['features'] as List).isNotEmpty)
                    ...((widget.listing['features'] as List).map((a) => _buildAmenity(a.toString())))
                  else 
                    Text('La propiedad no describe caracteristicas', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
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
                        if(isOwner) ...[
                          Row(
                            children: [
                              if (!isRented)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    await ListingService().deleteListing(widget.listing['id']);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Propiedad eliminada')));
                                    context.pop(true);
                                  }
                                ),
                              const SizedBox(width: 8),
                              if (!isRented)
                                SizedBox(
                                  width: 140,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      final nextStatus = isReview ? 'active' : 'review';
                                      await ListingService().updateListingStatus(widget.listing['id'], nextStatus);
                                      if (mounted) {
                                        setState(() {
                                          widget.listing['status'] = nextStatus;
                                        });
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isReview ? 'Publicado de nuevo' : 'Cambiado a revisión')));
                                      context.pop(true);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.lg),
                                      ),
                                    ),
                                    child: Text(
                                      isReview ? 'Publicar' : 'A Revisión',
                                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                )
                            ]
                          )
                        ] else if (isRenter && isRented)
                          SizedBox(
                            width: 160,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                await ListingService().completeRental(widget.listing['id']);
                                if (mounted) {
                                  setState(() {
                                    widget.listing['status'] = 'review';
                                  });
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Arriendo finalizado. Queda en revisión.')),
                                );
                                context.pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                              ),
                              child: Text(
                                'Finalizar arriendo',
                                style: AppTextStyles.label
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          )
                        else if (!isRented && !isReview)
                          SizedBox(
                            width: 120,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => context.push('/checkout', extra: widget.listing),
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

  Widget _buildStatusChip() {
    final status = widget.listing['status']?.toString().toLowerCase() ?? 'active';
    Color color = AppColors.success;
    String text = 'Activo';
    
    if (status == 'rented') {
      color = Colors.blue;
      text = 'Arrendado';
    } else if (status == 'review') {
      color = Colors.orange;
      text = 'En Revisión';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
