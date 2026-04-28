import 'terreno_model.dart';

class Listing {
  final String id;
  final String title;
  final String location;
  final num priceMonthly;
  final String imageUrl;
  final num? ndviScore;
  final num? rating;
  final num? sizeHectares;

  Listing({
    required this.id,
    required this.title,
    required this.location,
    required this.priceMonthly,
    required this.imageUrl,
    this.ndviScore,
    this.rating,
    this.sizeHectares,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final images = json['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url'] as String? ?? ''
        : (json['imageUrl'] as String? ?? '');

    return Listing(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: '${location['city'] ?? ''}, ${location['country'] ?? ''}'.trim(),
      priceMonthly: json['priceMonthly'] as num? ?? 0,
      imageUrl: imageUrl,
      ndviScore: json['ndviScore'] as num?,
      rating: json['ratingAvg'] as num?,
      sizeHectares: json['sizeHectares'] as num?,
    );
  }

  factory Listing.fromTerreno(Terreno terreno) {
    return Listing(
      id: terreno.id,
      title: terreno.title,
      location: terreno.getLocationString(),
      priceMonthly: terreno.priceMonthly,
      imageUrl: terreno.getFirstImage(),
      ndviScore: terreno.ndviData?['score'] as num?,
      rating: terreno.ratingAvg,
      sizeHectares: terreno.sizeHectares,
    );
  }
}
