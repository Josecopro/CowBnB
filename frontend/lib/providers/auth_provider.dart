import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Auth State Model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? userProfile;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.userProfile,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? userProfile,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

/// Auth Provider - Manages authentication state
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AuthState _state = AuthState();

  AuthState get state => _state;

  User? get currentUser => _state.user;

  bool get isAuthenticated => _state.isAuthenticated;

  String? get userRole => _state.userProfile?['role'];

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _state = AuthState();
      } else {
        _state = _state.copyWith(user: user);
      }
      notifyListeners();
    });
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phonePrefix,
    required String phone,
    required String role,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.code),
      );
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _state = _state.copyWith(
        user: userCredential.user,
        isLoading: false,
      );
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e.code),
      );
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      await _auth.signOut();

      _state = AuthState();
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to sign out',
      );
      notifyListeners();
    }
  }

  /// Set user profile data
  void setUserProfile(Map<String, dynamic> profile) {
    _state = _state.copyWith(userProfile: profile);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  /// Get error message from Firebase error code
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'An error occurred: $code';
    }
  }
}
