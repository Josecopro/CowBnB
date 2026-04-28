import 'package:cloud_firestore/cloud_firestore.dart';

class Reserva {
  final String id;
  final String renterId;
  final String ownerId;
  final String terrenoId;
  final DateTime startDate;
  final DateTime endDate;
  final num priceMonthly;
  final num totalAmount;
  final String status;
  final String paymentStatus;
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
