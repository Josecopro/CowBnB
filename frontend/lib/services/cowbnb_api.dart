import 'package:flutter/material.dart';
import '../models/api_models.dart';
import 'api_client.dart';

class CowbnbApi {
  CowbnbApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ExploreData> fetchExplore() async {
    final response = await _client.getJson('/terrenos', query: {
      'status': 'disponible',
      'orderBy': 'createdAt',
      'order': 'desc',
      'limit': '10',
    });

    final items = (response['items'] as List<dynamic>? ?? [])
        .map((item) => Listing.fromJson(item as Map<String, dynamic>))
        .toList();

    final notifications = await fetchNotifications();

    return ExploreData(listings: items, notifications: notifications);
  }

  Future<List<AppNotification>> fetchNotifications({String? userId}) async {
    final response = await _client.getJson('/notifications', query: {
      if (userId != null) 'userId': userId,
    });

    return (response['items'] as List<dynamic>? ?? [])
        .map((item) => _toNotification(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConversationItem>> fetchConversations({String? userId}) async {
    final response = await _client.getJson('/conversations', query: {
      if (userId != null) 'userId': userId,
    });

    return (response['items'] as List<dynamic>? ?? [])
        .map((item) => ConversationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<FavoriteListing>> fetchFavorites({String? userId}) async {
    final response = await _client.getJson('/favorites', query: {
      if (userId != null) 'userId': userId,
    });

    return (response['items'] as List<dynamic>? ?? [])
        .map((item) => FavoriteListing.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OwnerDashboardData> fetchOwnerDashboard({String? ownerId}) async {
    final response = await _client.getJson('/dashboard/owner', query: {
      if (ownerId != null) 'ownerId': ownerId,
    });

    return OwnerDashboardData.fromJson(response);
  }

  Future<RenterDashboardData> fetchRenterDashboard({String? renterId}) async {
    final response = await _client.getJson('/dashboard/renter', query: {
      if (renterId != null) 'renterId': renterId,
    });

    return RenterDashboardData.fromJson(response);
  }

  Future<Listing> fetchListing(String id) async {
    final response = await _client.getJson('/terrenos/$id');
    return Listing.fromJson(response['item'] as Map<String, dynamic>);
  }

  Future<void> createReserva(ReservaPayload payload) async {
    await _client.postJson('/reservas', body: payload.toJson());
  }

  AppNotification _toNotification(Map<String, dynamic> json) {
    final iconName = json['icon'] as String? ?? 'notifications';
    final icon = _iconFromName(iconName);
    return AppNotification(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      time: json['time'] as String? ?? '',
      icon: icon,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'message':
        return Icons.message;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'travel_explore':
        return Icons.travel_explore;
      case 'chat_bubble':
        return Icons.chat_bubble;
      case 'payments':
        return Icons.payments;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}
