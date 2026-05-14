import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../components/notifications_modal.dart';

class AppNotificationData {
  final String id;
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final int timestamp;
  final bool read;
  final IconData icon;

  const AppNotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.data = const {},
    required this.timestamp,
    this.read = false,
    this.icon = Icons.notifications,
  });

  factory AppNotificationData.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final iconName = data['icon'] as String? ?? 'notifications';
    return AppNotificationData(
      id: snapshot.key ?? '',
      type: data['type'] as String? ?? 'system',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      timestamp: data['timestamp'] as int? ?? 0,
      read: data['read'] as bool? ?? false,
      icon: _iconFromString(iconName),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'description': description,
    'data': data,
    'timestamp': timestamp,
    'read': read,
    'icon': _iconToString(icon),
  };

  AppNotification toLegacy() => AppNotification(
    title: title,
    description: description,
    time: _formatTimestamp(timestamp),
    isRead: read,
    icon: icon,
  );

  static String _formatTimestamp(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${dt.day}/${dt.month}';
  }

  static IconData _iconFromString(String name) {
    switch (name) {
      case 'message': return Icons.message;
      case 'booking': return Icons.calendar_today;
      case 'payment': return Icons.payments;
      case 'check_circle': return Icons.check_circle;
      case 'chat_bubble': return Icons.chat_bubble;
      case 'travel_explore': return Icons.travel_explore;
      default: return Icons.notifications;
    }
  }

  static String _iconToString(IconData icon) {
    if (icon == Icons.message) return 'message';
    if (icon == Icons.calendar_today) return 'booking';
    if (icon == Icons.payments) return 'payment';
    if (icon == Icons.check_circle) return 'check_circle';
    if (icon == Icons.chat_bubble) return 'chat_bubble';
    if (icon == Icons.travel_explore) return 'travel_explore';
    return 'notifications';
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference get _notificationsRef => _db.child('notifications');

  String? get _userId => _auth.currentUser?.uid;

  Stream<List<AppNotificationData>> notificationsStream() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    return _notificationsRef
        .child(uid)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final list = <AppNotificationData>[];
      for (final child in event.snapshot.children) {
        list.add(AppNotificationData.fromSnapshot(child));
      }
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<int> unreadCountStream() {
    return notificationsStream().map(
      (notifications) => notifications.where((n) => !n.read).length,
    );
  }

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String description,
    Map<String, dynamic>? data,
    String icon = 'notifications',
  }) async {
    final ref = _notificationsRef.child(recipientId).push();
    final now = DateTime.now().millisecondsSinceEpoch;

    final body = {
      'type': type,
      'title': title,
      'description': description,
      'data': data ?? {},
      'timestamp': now,
      'read': false,
      'icon': icon,
    };

    await ref.set(body);
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _userId;
    if (uid == null) return;
    await _notificationsRef.child(uid).child(notificationId).child('read').set(true);
  }

  Future<void> markAllAsRead() async {
    final uid = _userId;
    if (uid == null) return;
    final snapshot = await _notificationsRef.child(uid).get();
    if (!snapshot.exists) return;
    final updates = <String, dynamic>{};
    for (final child in snapshot.children) {
      updates['${child.key}/read'] = true;
    }
    await _notificationsRef.child(uid).update(updates);
  }

  Future<void> deleteNotification(String notificationId) async {
    final uid = _userId;
    if (uid == null) return;
    await _notificationsRef.child(uid).child(notificationId).remove();
  }
}
