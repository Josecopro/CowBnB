import 'package:flutter/material.dart';
import '../../design_tokens.dart';
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
  List<dynamic> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favs = await _authService.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favs;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String id) async {
    try {
      await _authService.removeFavorite(id);
      _loadFavorites();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al remover favorito')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Favoritos', style: AppTextStyles.headlineSmall),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(child: Text("Aún no tienes favoritos"))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    final String imageUrl = (fav['images'] != null && fav['images'].isNotEmpty) 
                        ? (fav['images'][0]['url'] ?? 'https://placehold.co/400x300.png')
                        : 'https://placehold.co/400x300.png';
                        
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ListingDetailsPage(listing: fav)),
                          ).then((_) => _loadFavorites());
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.md)),
                              child: Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fav['title'] ?? 'Sin título', 
                                      style: AppTextStyles.headlineSmall.copyWith(fontSize: 16), 
                                      maxLines: 1, overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 4),
                                    Text('\$${fav['price'] ?? 0} / mes', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _removeFavorite(fav['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
