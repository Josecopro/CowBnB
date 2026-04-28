import 'package:cloud_firestore/cloud_firestore.dart';

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
