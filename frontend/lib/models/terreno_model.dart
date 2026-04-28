import 'package:cloud_firestore/cloud_firestore.dart';

class Terreno {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final num sizeHectares;
  final num priceMonthly;
  final String status;
  final Map<String, dynamic>? location;
  final String? geohash;
  final List<String>? images;
  final String? coverImageUrl;
  final List<String>? features;
  final num? ratingAvg;
  final int? ratingCount;
  final Map<String, dynamic>? ndviData;
  final List<Map<String, dynamic>>? statusHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Terreno({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.sizeHectares,
    required this.priceMonthly,
    required this.status,
    this.location,
    this.geohash,
    this.images,
    this.coverImageUrl,
    this.features,
    this.ratingAvg,
    this.ratingCount,
    this.ndviData,
    this.statusHistory,
    this.createdAt,
    this.updatedAt,
  });

  factory Terreno.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final images = json['images'] as List<dynamic>? ?? [];
    final coverImageUrl = json['coverImageUrl'] as String?;

    return Terreno(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sizeHectares: json['sizeHectares'] as num? ?? 0,
      priceMonthly: json['priceMonthly'] as num? ?? 0,
      status: json['status'] as String? ?? 'disponible',
      location: location,
      geohash: json['geohash'] as String?,
      images: List<String>.from(images.whereType<String>()),
      coverImageUrl: coverImageUrl,
      features: List<String>.from(
        (json['features'] as List<dynamic>? ?? []).whereType<String>(),
      ),
      ratingAvg: json['ratingAvg'] as num?,
      ratingCount: json['ratingCount'] as int?,
      ndviData: json['ndviData'] as Map<String, dynamic>?,
      statusHistory:
          (json['statusHistory'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'sizeHectares': sizeHectares,
      'priceMonthly': priceMonthly,
      'status': status,
      'location': location,
      'geohash': geohash,
      'images': images,
      'coverImageUrl': coverImageUrl,
      'features': features,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'ndviData': ndviData,
      'statusHistory': statusHistory,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String getLocationString() {
    if (location == null) return 'Sin ubicación';
    final city = location!['city'] ?? '';
    final country = location!['country'] ?? '';
    return '$city, $country'.trim();
  }

  String getFirstImage() {
    return coverImageUrl ?? (images?.isNotEmpty == true ? images!.first : '');
  }
}
