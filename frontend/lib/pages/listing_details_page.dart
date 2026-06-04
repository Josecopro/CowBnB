import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../design_tokens.dart';
import '../components/optimized_network_image.dart';
import '../services/listing_service.dart';
import '../services/auth_service.dart';
import '../services/reservation_service.dart';
import '../services/chat_service.dart';

enum _ListingStatus { active, rented, review, unknown }

class ListingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> listing;
  const ListingDetailsPage({super.key, required this.listing});

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;
  bool _isFavorited = false;
  bool _hasBooking = false;
  bool _isLoadingFavorite = false;
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkFavorite();
    _checkBooking();

    final listingId = widget.listing['id']?.toString();
    if (listingId != null) {
      ListingService().recordView(listingId);
    }

    final images = _getImageUrls();
    if (images.length > 1) {
      _startCarouselTimer();
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    final id = widget.listing['id']?.toString();
    if (id == null) return;
    try {
      final favs = await _authService.getFavorites();
      if (!mounted) return;
      setState(() {
        _isFavorited = favs.any((f) => f['id']?.toString() == id);
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final id = widget.listing['id']?.toString();
    if (id == null || _isLoadingFavorite) return;
    setState(() => _isLoadingFavorite = true);
    HapticFeedback.selectionClick();
    try {
      if (_isFavorited) {
        await _authService.removeFavorite(id);
      } else {
        await _authService.addFavorite(id);
      }
      if (!mounted) return;
      setState(() => _isFavorited = !_isFavorited);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el favorito')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _checkBooking() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final listingId = widget.listing['id']?.toString();
    if (currentUid == null || listingId == null) return;
    try {
      bool hasBooking = false;
      final renterReservations = await ReservationService().getMyReservations();
      hasBooking = renterReservations.any((r) {
        final m = r as Map<String, dynamic>;
        final status = m['status']?.toString();
        return m['listingId']?.toString() == listingId &&
            (status == 'confirmed' ||
                status == 'active' ||
                status == 'completed');
      });
      if (!hasBooking) {
        final ownerReservations =
            await ReservationService().getOwnerReservations();
        hasBooking = ownerReservations.any((r) {
          final m = r as Map<String, dynamic>;
          final status = m['status']?.toString();
          return m['listingId']?.toString() == listingId &&
              (status == 'confirmed' ||
                  status == 'active' ||
                  status == 'completed');
        });
      }
      if (!mounted) return;
      setState(() => _hasBooking = hasBooking);
    } catch (_) {}
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final images = _getImageUrls();
      if (!_pageController.hasClients || images.length < 2) return;
      final next = (_currentPage + 1) % images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _openChat() async {
    final listingId = widget.listing['id']?.toString();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final ownerId = widget.listing['ownerId']?.toString();
    final renterId = widget.listing['renterId']?.toString();
    final title = widget.listing['title']?.toString() ?? 'Terreno';
    final otherUserId = currentUid == ownerId ? renterId : ownerId;
    if (otherUserId == null || otherUserId.isEmpty) return;
    try {
      final conversationId = await _chatService.createConversation(
        otherUserId: otherUserId,
        listingTitle: title,
        listingId: listingId,
      );
      if (!mounted) return;
      context.push(
        '/chat?id=$conversationId&title=${Uri.encodeComponent(title)}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al abrir el chat')),
      );
    }
  }

  List<String> _getImageUrls() {
    final imgs = widget.listing['images'];
    if (imgs is List) {
      return imgs.map((e) => e.toString()).toList();
    }
    return const [];
  }

  _ListingStatus _parseStatus() {
    final raw = widget.listing['status']?.toString().toLowerCase();
    switch (raw) {
      case 'rented':
        return _ListingStatus.rented;
      case 'review':
        return _ListingStatus.review;
      case 'active':
        return _ListingStatus.active;
      default:
        return _ListingStatus.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _getImageUrls();
    final status = _parseStatus();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == widget.listing['ownerId'];
    final isRenter = currentUid != null && currentUid == widget.listing['renterId'];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: AppColors.darkBg,
            foregroundColor: AppColors.onDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: _FloatingPillButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Volver',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/explore');
                }
              },
            ),
            actions: [
              if (!isOwner)
                _FloatingPillButton(
                  icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
                  semanticLabel: _isFavorited
                      ? 'Quitar de favoritos'
                      : 'Agregar a favoritos',
                  tint: _isFavorited ? AppColors.accent : null,
                  onPressed: _toggleFavorite,
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageCarousel(
                images: images,
                controller: _pageController,
                currentPage: _currentPage,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                  if (images.length > 1) _startCarouselTimer();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Semantics(
              container: true,
              label: 'Detalle del terreno',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleBlock(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickFacts(),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDescription(),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildOwnerBlock(),
                    if (_hasFeatures()) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFeatures(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLocationBlock(),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.borderSoft, width: 1),
            ),
            boxShadow: AppShadows.overlay,
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _buildBottomBar(isOwner: isOwner, isRenter: isRenter, status: status),
        ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    final title = widget.listing['title']?.toString() ?? 'Terreno sin título';
    final city = _locationCity();
    final country = _locationCountry();
    final location = (city != null && country != null)
        ? '$city, $country'
        : (city ?? country ?? widget.listing['location']?.toString() ?? 'Ubicación por confirmar');
    final status = _parseStatus();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusPill(status: status),
            const Spacer(),
            if (_hasRating())
              _RatingBadge(
                rating: widget.listing['rating'],
                reviewCount: widget.listing['reviewCount'],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppTextStyles.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 16,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFacts() {
    final size = widget.listing['size'];
    final ndvi = widget.listing['ndviDetectado'];
    final soil = widget.listing['soil_type'];
    final irrigation = widget.listing['irrigation'];

    final facts = <(IconData, String, String)>[
      (
        Icons.landscape_outlined,
        'Tamaño',
        size != null ? '$size ha' : '—',
      ),
      (
        Icons.grass_outlined,
        'NDVI',
        ndvi != null
            ? (ndvi as num).toStringAsFixed(2)
            : '—',
      ),
      (
        Icons.layers_outlined,
        'Suelo',
        soil?.toString() ?? '—',
      ),
      (
        Icons.water_drop_outlined,
        'Riego',
        irrigation?.toString() ?? '—',
      ),
    ];

    return Semantics(
      container: true,
      label: 'Datos del terreno',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            Expanded(
              child: _QuickFact(
                icon: facts[i].$1,
                label: facts[i].$2,
                value: facts[i].$3,
              ),
            ),
            if (i < facts.length - 1)
              Container(
                width: 1,
                height: 40,
                color: AppColors.borderSoft,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final desc = widget.listing['description']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acerca de este terreno', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          (desc == null || desc.isEmpty)
              ? 'El propietario aún no agregó una descripción para este terreno.'
              : desc,
          style: AppTextStyles.body.copyWith(
            color: (desc == null || desc.isEmpty)
                ? AppColors.inkMuted
                : AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerBlock() {
    final ownerName = widget.listing['ownerName']?.toString() ??
        widget.listing['ownerDisplayName']?.toString() ??
        'Propietario verificado';
    final joinedYear = widget.listing['ownerJoinedYear']?.toString();
    final responseRate = widget.listing['ownerResponseRate']?.toString();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(ownerName),
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ownerName, style: AppTextStyles.title),
                const SizedBox(height: 2),
                Text(
                  [
                    if (joinedYear != null) 'En CowBnB desde $joinedYear',
                    if (responseRate != null) 'Responde el $responseRate% de los mensajes',
                  ].join(' • '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasFeatures() {
    final features = widget.listing['features'];
    return features is List && features.isNotEmpty;
  }

  Widget _buildFeatures() {
    final features = (widget.listing['features'] as List)
        .map((e) => e.toString())
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Características', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in features)
              _FeatureChip(label: f),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationBlock() {
    final city = _locationCity();
    return Row(
      children: [
        const Icon(Icons.map_outlined, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            city != null ? 'Ubicación: $city' : 'Ubicación a confirmar',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }

  String? _locationCity() =>
      (widget.listing['location'] is Map)
          ? widget.listing['location']['city']?.toString()
          : null;

  String? _locationCountry() =>
      (widget.listing['location'] is Map)
          ? widget.listing['location']['country']?.toString()
          : null;

  bool _hasRating() {
    final r = widget.listing['rating'];
    final c = widget.listing['reviewCount'];
    return r != null && c is num && c > 0;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '·';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildBottomBar({
    required bool isOwner,
    required bool isRenter,
    required _ListingStatus status,
  }) {
    final price = widget.listing['price']?.toString() ?? '0';
    final priceLabel = '\$$price / mes';

    if (isOwner) {
      return _buildOwnerActions(status);
    }
    if (isRenter && status == _ListingStatus.rented) {
      return _buildPrimaryAction(
        label: 'Finalizar arriendo',
        onPressed: () => _completeRental(),
        priceLabel: priceLabel,
        icon: Icons.check_circle_outline,
      );
    }
    if (_hasBooking) {
      return _buildPrimaryAction(
        label: 'Contactar al propietario',
        onPressed: _openChat,
        priceLabel: priceLabel,
        icon: Icons.chat_bubble_outline,
      );
    }
    if (status == _ListingStatus.rented) {
      return _buildDisabledAction(
        label: 'No disponible',
        priceLabel: priceLabel,
        message: 'Este terreno ya está arrendado.',
      );
    }
    if (status == _ListingStatus.review) {
      return _buildDisabledAction(
        label: 'En revisión',
        priceLabel: priceLabel,
        message: 'El propietario está revisando esta publicación.',
      );
    }
    return _buildPrimaryAction(
      label: 'Reservar',
      onPressed: () => context.push('/checkout', extra: widget.listing),
      priceLabel: priceLabel,
      icon: Icons.event_available_outlined,
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required VoidCallback onPressed,
    required String priceLabel,
    required IconData icon,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Precio mensual', style: AppTextStyles.labelSmall),
              const SizedBox(height: 2),
              Text(priceLabel, style: AppTextStyles.headline),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: AppTextStyles.label,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledAction({
    required String label,
    required String priceLabel,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(priceLabel, style: AppTextStyles.headline),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: AppColors.inkMuted,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerActions(_ListingStatus status) {
    final isRented = status == _ListingStatus.rented;
    final isReview = status == _ListingStatus.review;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isRented
                  ? null
                  : () => _confirmDelete(),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Eliminar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                disabledForegroundColor: AppColors.inkMuted,
                side: BorderSide(
                  color: isRented ? AppColors.border : AppColors.danger,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: AppTextStyles.label,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: isRented ? null : () => _toggleReview(isReview),
              icon: Icon(
                isReview ? Icons.publish : Icons.assignment_outlined,
                size: 20,
              ),
              label: Text(isReview ? 'Publicar' : 'A revisión'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceContainer,
                foregroundColor: AppColors.onPrimary,
                disabledForegroundColor: AppColors.inkMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: AppTextStyles.label,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('¿Eliminar publicación?', style: AppTextStyles.title),
        content: Text(
          'Esta acción no se puede deshacer. Los arrendatarios con reservas activas serán notificados.',
          style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ListingService().deleteListing(widget.listing['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la publicación')),
      );
    }
  }

  Future<void> _toggleReview(bool currentlyReview) async {
    final nextStatus = currentlyReview ? 'active' : 'review';
    try {
      await ListingService()
          .updateListingStatus(widget.listing['id'], nextStatus);
      if (!mounted) return;
      setState(() {
        widget.listing['status'] = nextStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyReview ? 'Publicación activa' : 'Marcada para revisión',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cambiar el estado')),
      );
    }
  }

  Future<void> _completeRental() async {
    try {
      await ListingService().completeRental(widget.listing['id']);
      if (!mounted) return;
      setState(() {
        widget.listing['status'] = 'review';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arriendo finalizado. Quedó en revisión.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo finalizar el arriendo')),
      );
    }
  }
}

class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _ImageCarousel({
    required this.images,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.surfaceContainer,
        alignment: Alignment.center,
        child: const Icon(
          Icons.terrain_outlined,
          size: 72,
          color: AppColors.inkSoft,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: controller,
          onPageChanged: onPageChanged,
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Semantics(
              label:
                  'Imagen ${index + 1} de ${images.length} del terreno',
              child: AppNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                memCacheWidth: 1280,
                width: double.infinity,
                height: double.infinity,
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBgDeep.withValues(alpha: 0.0),
                  AppColors.darkBgDeep.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _CarouselCounter(
              current: currentPage + 1,
              total: images.length,
            ),
          ),
      ],
    );
  }
}

class _CarouselCounter extends StatelessWidget {
  final int current;
  final int total;
  const _CarouselCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkBgDeep.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$current / $total',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onDark,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _FloatingPillButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final Color? tint;

  const _FloatingPillButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: AppColors.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 20,
                color: tint ?? AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _ListingStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(status);
    return Semantics(
      label: 'Estado: ${spec.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: spec.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, size: 14, color: spec.foreground),
            const SizedBox(width: 6),
            Text(
              spec.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: spec.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusSpec _specFor(_ListingStatus s) {
    switch (s) {
      case _ListingStatus.active:
        return const _StatusSpec(
          label: 'Disponible',
          icon: Icons.bolt_outlined,
          background: AppColors.primarySoft,
          foreground: AppColors.primaryInk,
        );
      case _ListingStatus.rented:
        return const _StatusSpec(
          label: 'Arrendado',
          icon: Icons.lock_outline,
          background: AppColors.surfaceContainer,
          foreground: AppColors.inkMuted,
        );
      case _ListingStatus.review:
        return const _StatusSpec(
          label: 'En revisión',
          icon: Icons.schedule_outlined,
          background: Color(0xFFFCEFD8),
          foreground: AppColors.warning,
        );
      case _ListingStatus.unknown:
        return const _StatusSpec(
          label: 'Borrador',
          icon: Icons.edit_outlined,
          background: AppColors.surfaceContainer,
          foreground: AppColors.inkMuted,
        );
    }
  }
}

class _StatusSpec {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _StatusSpec({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });
}

class _RatingBadge extends StatelessWidget {
  final dynamic rating;
  final dynamic reviewCount;
  const _RatingBadge({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    final r = (rating as num?)?.toStringAsFixed(1) ?? '—';
    final c = (reviewCount as num?)?.toInt() ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
        const SizedBox(width: 2),
        Text(r, style: AppTextStyles.label),
        const SizedBox(width: 4),
        Text(
          '($c)',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _QuickFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _QuickFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryInk),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.title),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppColors.primaryInk,
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
