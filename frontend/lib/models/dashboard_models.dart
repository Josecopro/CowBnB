import 'listing_model.dart';
import 'notification_model.dart';
import 'reserva_model.dart';

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

class ExploreData {
  ExploreData({required this.listings, required this.notifications});

  final List<Listing> listings;
  final List<AppNotification> notifications;
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
