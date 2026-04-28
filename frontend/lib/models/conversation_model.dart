import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;
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
