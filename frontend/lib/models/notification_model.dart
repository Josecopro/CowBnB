import 'package:flutter/material.dart';

class AppNotification {
  const AppNotification({
    required this.title,
    required this.description,
    required this.time,
    this.isRead = false,
    this.icon = Icons.notifications,
  });

  final String title;
  final String description;
  final String time;
  final bool isRead;
  final IconData icon;
}
