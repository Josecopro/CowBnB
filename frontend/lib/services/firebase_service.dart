import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'firebase_options.dart';

final logger = Logger();

/// Firebase Service - Initialization and singleton instances
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable offline persistence for Firestore
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      logger.i('Firebase initialized successfully');
    } catch (e) {
      logger.e('Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Get Firebase Auth instance
  FirebaseAuth get auth {
    _auth = FirebaseAuth.instance;
    return _auth;
  }

  /// Get Firestore instance
  FirebaseFirestore get firestore {
    _firestore = FirebaseFirestore.instance;
    return _firestore;
  }

  /// Get Firebase Storage instance
  FirebaseStorage get storage {
    _storage = FirebaseStorage.instance;
    return _storage;
  }

  /// Get current user
  User? get currentUser => auth.currentUser;

  /// Get current user ID
  String? get currentUserId => auth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => auth.currentUser?.email;

  /// Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;

  /// Get user's ID token
  Future<String?> getIdToken() async {
    try {
      return await auth.currentUser?.getIdToken();
    } catch (e) {
      logger.e('Failed to get ID token: $e');
      return null;
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phonePrefix,
    required String phone,
    required String role,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      await userCredential.user?.updateProfile(displayName: fullName);

      // Create Firestore user document
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': fullName,
        'email': email,
        'phonePrefix': phonePrefix,
        'phone': phone,
        'role': role,
        'acceptedTerms': true,
        'onboardingComplete': false,
        'status': 'active',
        'bio': null,
        'location': null,
        'profileImageUrl': null,
        'fcmTokens': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.i('User signed up: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Sign up failed: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i('User signed in: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Sign in failed: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      logger.i('User signed out');
    } catch (e) {
      logger.e('Sign out failed: $e');
      rethrow;
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      logger.e('Failed to get user profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await firestore.collection('users').doc(uid).update(data);
      logger.i('User profile updated: $uid');
    } catch (e) {
      logger.e('Failed to update user profile: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      logger.i('Password reset email sent to: $email');
    } catch (e) {
      logger.e('Failed to send password reset email: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<User?> authStateChanges() {
    return auth.authStateChanges();
  }

  /// Listen to user data changes in Firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>>? userDataStream(String uid) {
    try {
      return firestore.collection('users').doc(uid).snapshots();
    } catch (e) {
      logger.e('Failed to get user data stream: $e');
      return null;
    }
  }
}
