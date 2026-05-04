class ListingModel {
  final String id;
  final String title;
  final String description;
  final num size;
  final num price;
  final List<String> features;
  final List<String> images;
  final String ownerId;
  final String createdAt;

  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.size,
    required this.price,
    required this.features,
    required this.images,
    required this.ownerId,
    required this.createdAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      size: json['size'] ?? 0,
      price: json['price'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      ownerId: json['ownerId'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
