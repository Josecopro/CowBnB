import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phonePrefix;
  final String phone;
  final String role;
  final String status;
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
