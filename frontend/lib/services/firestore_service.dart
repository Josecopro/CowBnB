import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Firestore Service - CRUD operations wrapper
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // TERRENOS COLLECTION OPERATIONS
  // ============================================================================

  /// Create a new terreno
  Future<String> createTerreno(Map<String, dynamic> data) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('terrenos').add(data);
      logger.i('Terreno created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger.e('Failed to create terreno: $e');
      rethrow;
    }
  }

  /// Get a single terreno by ID
  Future<Map<String, dynamic>?> getTerreno(String terrenoId) async {
    try {
      final doc = await _firestore.collection('terrenos').doc(terrenoId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      logger.e('Failed to get terreno: $e');
      rethrow;
    }
  }

  /// Get stream of a single terreno for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> getTerrenoStream(
      String terrenoId) {
    return _firestore.collection('terrenos').doc(terrenoId).snapshots();
  }

  /// List all terrenos with optional filters
  Future<List<Map<String, dynamic>>> listTerrenos({
    String? ownerId,
    String? status,
    int? limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('terrenos');

      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      query = query
          .orderBy('createdAt', descending: true)
          .limit(limit ?? 20);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      logger.e('Failed to list terrenos: $e');
      rethrow;
    }
  }

  /// Get stream of terrenos for real-time updates
  Stream<QuerySnapshot<Map<String, dynamic>>> getTerrnosStream({
    String? ownerId,
    String? status,
    int? limit = 20,
  }) {
    Query query = _firestore.collection('terrenos');

    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query
        .orderBy('createdAt', descending: true)
        .limit(limit ?? 20);

    return query.snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  /// Update a terreno
  Future<void> updateTerreno(
    String terrenoId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('terrenos').doc(terrenoId).update(data);
      logger.i('Terreno updated: $terrenoId');
    } catch (e) {
      logger.e('Failed to update terreno: $e');
      rethrow;
    }
  }

  /// Delete a terreno (soft delete via status field)
  Future<void> deleteTerreno(String terrenoId) async {
    try {
      await _firestore.collection('terrenos').doc(terrenoId).update({
        'status': 'inactivo',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i('Terreno deleted: $terrenoId');
    } catch (e) {
      logger.e('Failed to delete terreno: $e');
      rethrow;
    }
  }

  // ============================================================================
  // RESERVAS COLLECTION OPERATIONS
  // ============================================================================

  /// Create a new reserva
  Future<String> createReserva(Map<String, dynamic> data) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('reservas').add(data);
      logger.i('Reserva created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger.e('Failed to create reserva: $e');
      rethrow;
    }
  }

  /// Get a single reserva by ID
  Future<Map<String, dynamic>?> getReserva(String reservaId) async {
    try {
      final doc = await _firestore.collection('reservas').doc(reservaId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      logger.e('Failed to get reserva: $e');
      rethrow;
    }
  }

  /// Get stream of reservas for a renter
  Stream<QuerySnapshot<Map<String, dynamic>>> getRenterReservasStream(
    String renterId,
  ) {
    return _firestore
        .collection('reservas')
        .where('renterId', isEqualTo: renterId)
        .orderBy('createdAt', descending: true)
        .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  /// Get stream of reservas for an owner
  Stream<QuerySnapshot<Map<String, dynamic>>> getOwnerReservasStream(
    String ownerId,
  ) {
    return _firestore
        .collection('reservas')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  // ============================================================================
  // FAVORITES COLLECTION OPERATIONS
  // ============================================================================

  /// Add a terreno to user's favorites
  Future<void> addToFavorites(String userId, String terrenoId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(terrenoId)
          .set({
        'terrenoId': terrenoId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      logger.i('Added to favorites: $terrenoId');
    } catch (e) {
      logger.e('Failed to add to favorites: $e');
      rethrow;
    }
  }

  /// Remove a terreno from user's favorites
  Future<void> removeFromFavorites(String userId, String terrenoId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(terrenoId)
          .delete();
      logger.i('Removed from favorites: $terrenoId');
    } catch (e) {
      logger.e('Failed to remove from favorites: $e');
      rethrow;
    }
  }

  /// Get user's favorite terrenos
  Stream<QuerySnapshot<Map<String, dynamic>>> getFavoritesStream(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  // ============================================================================
  // CONVERSATIONS OPERATIONS
  // ============================================================================

  /// Get user's conversations
  Stream<QuerySnapshot<Map<String, dynamic>>> getConversationsStream(
    String userId,
  ) {
    return _firestore
        .collection('conversaciones')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  /// Send a message in a conversation
  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String text,
  ) async {
    try {
      await _firestore
          .collection('conversaciones')
          .doc(conversationId)
          .collection('mensajes')
          .add({
        'senderId': senderId,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update conversation's lastMessage
      await _firestore.collection('conversaciones').doc(conversationId).update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });

      logger.i('Message sent in conversation: $conversationId');
    } catch (e) {
      logger.e('Failed to send message: $e');
      rethrow;
    }
  }

  /// Get messages in a conversation
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
    String conversationId,
  ) {
    return _firestore
        .collection('conversaciones')
        .doc(conversationId)
        .collection('mensajes')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  // ============================================================================
  // REVIEWS OPERATIONS
  // ============================================================================

  /// Create a review
  Future<String> createReview(Map<String, dynamic> data) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('reviews').add(data);
      logger.i('Review created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger.e('Failed to create review: $e');
      rethrow;
    }
  }

  /// Get reviews for a terreno
  Stream<QuerySnapshot<Map<String, dynamic>>> getReviewsStream(
    String terrenoId,
  ) {
    return _firestore
        .collection('reviews')
        .where('terrenoId', isEqualTo: terrenoId)
        .orderBy('createdAt', descending: true)
        .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  // ============================================================================
  // GENERIC OPERATIONS
  // ============================================================================

  /// Get a document from any collection
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(docId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      logger.e('Failed to get document: $e');
      rethrow;
    }
  }

  /// Update a document in any collection
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(collection).doc(docId).update(data);
      logger.i('Document updated: $collection/$docId');
    } catch (e) {
      logger.e('Failed to update document: $e');
      rethrow;
    }
  }

  /// Query documents with where conditions
  Future<List<Map<String, dynamic>>> queryDocuments(
    String collection, {
    required String field,
    required dynamic value,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(collection)
          .where(field, isEqualTo: value);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      logger.e('Failed to query documents: $e');
      rethrow;
    }
  }
}
