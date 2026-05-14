import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'notification_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  factory ChatMessage.fromSnapshot(DataSnapshot snapshot, {String? key}) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return ChatMessage(
      id: key ?? snapshot.key ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] as int? ?? 0,
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': timestamp,
    'read': read,
  };
}

class ChatConversation {
  final String id;
  final List<String> participants;
  final String listingTitle;
  final String? listingId;
  final String lastMessage;
  final int lastMessageTime;
  final String lastSenderId;
  final Map<String, int> unread;

  const ChatConversation({
    required this.id,
    required this.participants,
    required this.listingTitle,
    this.listingId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderId,
    this.unread = const {},
  });

  factory ChatConversation.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final unreadRaw = data['unread'] as Map<dynamic, dynamic>?;
    final unreadMap = <String, int>{};
    if (unreadRaw != null) {
      unreadRaw.forEach((k, v) => unreadMap[k.toString()] = (v as num).toInt());
    }
    return ChatConversation(
      id: snapshot.key ?? '',
      participants: List<String>.from(data['participants'] as List? ?? []),
      listingTitle: data['listingTitle'] as String? ?? '',
      listingId: data['listingId'] as String?,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageTime: data['lastMessageTime'] as int? ?? 0,
      lastSenderId: data['lastSenderId'] as String? ?? '',
      unread: unreadMap,
    );
  }
}

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? get currentUserId => _auth.currentUser?.uid;
  String? get _userId => currentUserId;
  String? get _userName =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Usuario';

  DatabaseReference get _messagesRef => _db.child('messages');
  DatabaseReference get _conversationsRef => _db.child('conversations');
  DatabaseReference get _userConversationsRef => _db.child('user_conversations');

  Future<String> createConversation({
    required String otherUserId,
    required String listingTitle,
    String? listingId,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Not authenticated');

    final convoRef = _conversationsRef.push();
    final convoId = convoRef.key!;
    final now = DateTime.now().millisecondsSinceEpoch;

    await convoRef.set({
      'participants': [uid, otherUserId],
      'listingTitle': listingTitle,
      'listingId': listingId ?? '',
      'lastMessage': '',
      'lastMessageTime': now,
      'lastSenderId': uid,
      'unread': {uid: 0, otherUserId: 0},
      'createdAt': now,
    });

    await _userConversationsRef.child(uid).child(convoId).set(true);
    await _userConversationsRef.child(otherUserId).child(convoId).set(true);

    return convoId;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Not authenticated');

    final now = DateTime.now().millisecondsSinceEpoch;
    final msgRef = _messagesRef.child(conversationId).push();

    await msgRef.set({
      'senderId': uid,
      'senderName': _userName,
      'text': text,
      'timestamp': now,
      'read': false,
    });

    final snapshot =
        await _conversationsRef.child(conversationId).child('participants').get();
    final participants = List<String>.from(snapshot.value as List? ?? []);
    final unreadMap = <String, int>{};
    for (final p in participants) {
      unreadMap[p] = p == uid ? 0 : 1;
    }

    await _conversationsRef.child(conversationId).update({
      'lastMessage': text,
      'lastMessageTime': now,
      'lastSenderId': uid,
      'unread': unreadMap,
    });

    final otherParticipant = participants.firstWhere(
      (p) => p != uid,
      orElse: () => '',
    );
    if (otherParticipant.isNotEmpty) {
      final convoSnapshot =
          await _conversationsRef.child(conversationId).child('listingTitle').get();
      final listingTitle = convoSnapshot.value?.toString() ?? '';

      final senderName = _userName ?? 'Usuario';
      NotificationService().createNotification(
        recipientId: otherParticipant,
        type: 'message',
        title: 'Nuevo mensaje',
        description: '$senderName te envió un mensaje${listingTitle.isNotEmpty ? ' sobre $listingTitle' : ''}',
        data: {
          'conversationId': conversationId,
          'senderName': senderName,
          'listingTitle': listingTitle,
        },
        icon: 'message',
      );
    }
  }

  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _messagesRef
        .child(conversationId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final messages = <ChatMessage>[];
      for (final child in event.snapshot.children) {
        messages.add(ChatMessage.fromSnapshot(child));
      }
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Stream<List<ChatConversation>> conversationsStream() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    return _conversationsRef.onValue.map((event) {
      final convos = <ChatConversation>[];
      for (final child in event.snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);
        final participants = List<String>.from(data['participants'] as List? ?? []);
        if (participants.contains(uid)) {
          convos.add(ChatConversation.fromSnapshot(child));
        }
      }
      convos.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return convos;
    });
  }

  Future<ChatConversation?> getConversation(String conversationId) async {
    final snapshot = await _conversationsRef.child(conversationId).get();
    if (!snapshot.exists) return null;
    return ChatConversation.fromSnapshot(snapshot);
  }

  Future<void> markAsRead(String conversationId) async {
    final uid = _userId;
    if (uid == null) return;

    await _conversationsRef
        .child(conversationId)
        .child('unread')
        .child(uid)
        .set(0);
  }
}
