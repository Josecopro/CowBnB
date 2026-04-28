class Listing {
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

  final String id;
  final String title;
  final String location;
  final num priceMonthly;
  final String imageUrl;
  final num? ndviScore;
  final num? rating;
  final num? sizeHectares;

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
}

class ConversationItem {
  ConversationItem({
    required this.name,
    required this.listing,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.avatarUrl,
  });

  final String name;
  final String listing;
  final String message;
  final String time;
  final int unreadCount;
  final String avatarUrl;

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      name: json['name'] as String? ?? '',
      listing: json['listing'] as String? ?? '',
      message: json['message'] as String? ?? '',
      time: json['time'] as String? ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }
}

class FavoriteListing {
  FavoriteListing({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.image,
    required this.hectares,
  });

  final String id;
  final String title;
  final String location;
  final String price;
  final String image;
  final String hectares;

  factory FavoriteListing.fromJson(Map<String, dynamic> json) {
    return FavoriteListing(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      price: json['price'] as String? ?? '',
      image: json['image'] as String? ?? '',
      hectares: json['hectares'] as String? ?? '',
    );
  }
}

class OwnerDashboardData {
  OwnerDashboardData({
    required this.stats,
    required this.properties,
    required this.notifications,
  });

  final DashboardStats stats;
  final List<Listing> properties;
  final List<dynamic> notifications;

  factory OwnerDashboardData.fromJson(Map<String, dynamic> json) {
    final properties = (json['properties'] as List<dynamic>? ?? [])
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();
    final notifications = (json['notifications'] as List<dynamic>? ?? []);

    return OwnerDashboardData(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      properties: properties,
      notifications: notifications,
    );
  }
}

class RenterDashboardData {
  RenterDashboardData({
    required this.stats,
    required this.reservas,
    required this.notifications,
  });

  final DashboardStats stats;
  final List<ReservaItem> reservas;
  final List<dynamic> notifications;

  factory RenterDashboardData.fromJson(Map<String, dynamic> json) {
    final reservas = (json['reservas'] as List<dynamic>? ?? [])
        .map((item) => ReservaItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final notifications = (json['notifications'] as List<dynamic>? ?? []);

    return RenterDashboardData(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      reservas: reservas,
      notifications: notifications,
    );
  }
}

class DashboardStats {
  DashboardStats({
    required this.propertiesCount,
    required this.activeReservationsCount,
    required this.rentersCount,
    required this.viewsCount,
    required this.favoritesCount,
    required this.messagesCount,
    required this.hectares,
  });

  final int propertiesCount;
  final int activeReservationsCount;
  final int rentersCount;
  final int viewsCount;
  final int favoritesCount;
  final int messagesCount;
  final num hectares;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      propertiesCount: json['propertiesCount'] as int? ?? 0,
      activeReservationsCount: json['activeReservationsCount'] as int? ?? 0,
      rentersCount: json['rentersCount'] as int? ?? 0,
      viewsCount: json['viewsCount'] as int? ?? 0,
      favoritesCount: json['favoritesCount'] as int? ?? 0,
      messagesCount: json['messagesCount'] as int? ?? 0,
      hectares: json['hectares'] as num? ?? 0,
    );
  }
}

class ReservaItem {
  ReservaItem({
    required this.listingId,
    required this.title,
    required this.location,
    required this.image,
    required this.status,
    required this.dates,
    required this.price,
  });

  final String listingId;
  final String title;
  final String location;
  final String image;
  final String status;
  final String dates;
  final String price;

  factory ReservaItem.fromJson(Map<String, dynamic> json) {
    return ReservaItem(
      listingId: json['listingId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      image: json['image'] as String? ?? '',
      status: json['status'] as String? ?? '',
      dates: json['dates'] as String? ?? '',
      price: json['price'] as String? ?? '',
    );
  }
}

class ExploreData {
  ExploreData({required this.listings, required this.notifications});

  final List<Listing> listings;
  final List<dynamic> notifications;
}

class ReservaPayload {
  ReservaPayload({
    required this.terrenoId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.priceMonthly,
  });

  final String terrenoId;
  final String renterId;
  final String ownerId;
  final int startDate;
  final int endDate;
  final num priceMonthly;

  Map<String, dynamic> toJson() {
    return {
      'terrenoId': terrenoId,
      'renterId': renterId,
      'ownerId': ownerId,
      'startDate': startDate,
      'endDate': endDate,
      'priceMonthly': priceMonthly,
    };
  }
}
