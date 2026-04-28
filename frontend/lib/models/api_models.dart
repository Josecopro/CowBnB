import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// USER MODEL
// ============================================================================
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phonePrefix;
  final String phone;
  final String role; // "owner" | "renter"
  final String status; // "active" | "suspended" | "deleted"
  final bool onboardingComplete;
  final String? bio;
  final String? profileImageUrl;
  final Map<String, dynamic>? location;
  final bool acceptedTerms;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phonePrefix,
    required this.phone,
    required this.role,
    required this.status,
    this.onboardingComplete = false,
    this.bio,
    this.profileImageUrl,
    this.location,
    this.acceptedTerms = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phonePrefix: json['phonePrefix'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'renter',
      status: json['status'] as String? ?? 'active',
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      bio: json['bio'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      location: json['location'] as Map<String, dynamic>?,
      acceptedTerms: json['acceptedTerms'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phonePrefix': phonePrefix,
      'phone': phone,
      'role': role,
      'status': status,
      'onboardingComplete': onboardingComplete,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'location': location,
      'acceptedTerms': acceptedTerms,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// ============================================================================
// TERRENO MODEL
// ============================================================================
class Terreno {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final num sizeHectares;
  final num priceMonthly;
  final String status; // "disponible" | "reservado" | "en_espera" | "inactivo"
  final Map<String, dynamic>? location;
  final String? geohash;
  final List<String>? images;
  final String? coverImageUrl;
  final List<String>? features; // ["riego", "energía", "caminos", "certificación"]
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
    final imageUrl = images.isNotEmpty
        ? (images.first as String?)
        : (coverImageUrl ?? '');

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

// ============================================================================
// LEGACY LISTING MODEL (for UI compatibility)
// ============================================================================
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

  /// Convert from Terreno model
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

// ============================================================================
// RESERVA MODEL
// ============================================================================
class Reserva {
  final String id;
  final String renterId;
  final String ownerId;
  final String terrenoId;
  final DateTime startDate;
  final DateTime endDate;
  final num priceMonthly;
  final num totalAmount;
  final String status; // "en_espera" | "reservado" | "cancelada"
  final String paymentStatus; // "pendiente" | "pagado" | "fallido"
  final String? paymentReference;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reserva({
    required this.id,
    required this.renterId,
    required this.ownerId,
    required this.terrenoId,
    required this.startDate,
    required this.endDate,
    required this.priceMonthly,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentReference,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as String? ?? '',
      renterId: json['renterId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      terrenoId: json['terrenoId'] as String? ?? '',
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priceMonthly: json['priceMonthly'] as num? ?? 0,
      totalAmount: json['totalAmount'] as num? ?? 0,
      status: json['status'] as String? ?? 'en_espera',
      paymentStatus: json['paymentStatus'] as String? ?? 'pendiente',
      paymentReference: json['paymentReference'] as String?,
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'renterId': renterId,
      'ownerId': ownerId,
      'terrenoId': terrenoId,
      'startDate': startDate,
      'endDate': endDate,
      'priceMonthly': priceMonthly,
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
    };
  }
}

// ============================================================================
// CONVERSATION MODEL
// ============================================================================
class Conversation {
  final String id;
  final List<String> participants; // [ownerId, renterId]
  final String reservaId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    required this.reservaId,
    required this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? '',
      participants: List<String>.from(json['participants'] as List<dynamic>? ?? []),
      reservaId: json['reservaId'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: (json['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ============================================================================
// MESSAGE MODEL
// ============================================================================
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime? sentAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.isRead,
    this.sentAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      sentAt: (json['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ============================================================================
// REVIEW MODEL
// ============================================================================
class Review {
  final String id;
  final String terrenoId;
  final String reviewerId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.terrenoId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      terrenoId: json['terrenoId'] as String? ?? '',
      reviewerId: json['reviewerId'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'terrenoId': terrenoId,
      'reviewerId': reviewerId,
      'rating': rating,
      'comment': comment,
    };
  }
}

// ============================================================================
// DASHBOARD MODELS (for backward compatibility)
// ============================================================================
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
