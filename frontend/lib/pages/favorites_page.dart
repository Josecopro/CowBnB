import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/optimized_network_image.dart';
import '../services/auth_service.dart';
import '../pages/listing_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final favs = await _authService.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _removeFavorite(String id) async {
    try {
      await _authService.removeFavorite(id);
      _loadFavorites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo quitar el favorito. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Mis Favoritos', style: AppTextStyles.headlineSmall),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorState()
              : _favorites.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final fav = _favorites[index];
                        final String imageUrl =
                            (fav['images'] != null && fav['images'].isNotEmpty)
                                ? fav['images'][0].toString()
                                : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Semantics(
                            button: true,
                            label: 'Terreno favorito ${fav['title'] ?? 'sin titulo'}',
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ListingDetailsPage(listing: fav)),
                                ).then((_) => _loadFavorites());
                              },
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(AppRadius.lg)),
                                      child: AppNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 400,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fav['title']?.toString() ?? 'Terreno sin titulo',
                                              style: AppTextStyles.label.copyWith(fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${fav['price'] ?? 0} / mes',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.inkMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.favorite, color: AppColors.danger),
                                      tooltip: 'Quitar de favoritos',
                                      onPressed: () => _removeFavorite(fav['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.favorite_border, size: 32, color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Aun no tienes favoritos',
                style: AppTextStyles.label, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Toca el corazon en cualquier terreno para guardarlo aqui.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Explorar terrenos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 32, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text('No pudimos cargar tus favoritos',
                style: AppTextStyles.label, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Revisa tu conexion e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
