import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Terreno State Model
class TerrenoState {
  final List<Map<String, dynamic>> terrenos;
  final Map<String, dynamic>? selectedTerreno;
  final bool isLoading;
  final String? error;
  final int pageSize;
  final String? filterStatus;
  final String? filterOwnerId;

  TerrenoState({
    this.terrenos = const [],
    this.selectedTerreno,
    this.isLoading = false,
    this.error,
    this.pageSize = 20,
    this.filterStatus,
    this.filterOwnerId,
  });

  TerrenoState copyWith({
    List<Map<String, dynamic>>? terrenos,
    Map<String, dynamic>? selectedTerreno,
    bool? isLoading,
    String? error,
    int? pageSize,
    String? filterStatus,
    String? filterOwnerId,
  }) {
    return TerrenoState(
      terrenos: terrenos ?? this.terrenos,
      selectedTerreno: selectedTerreno ?? this.selectedTerreno,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pageSize: pageSize ?? this.pageSize,
      filterStatus: filterStatus ?? this.filterStatus,
      filterOwnerId: filterOwnerId ?? this.filterOwnerId,
    );
  }
}

/// Terreno Provider - Manages terrenos state
class TerrenoProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  TerrenoState _state = TerrenoState();

  TerrenoState get state => _state;

  List<Map<String, dynamic>> get terrenos => _state.terrenos;

  bool get isLoading => _state.isLoading;

  String? get error => _state.error;

  /// Load terrenos with filters
  Future<void> loadTerrenos({
    String? ownerId,
    String? status,
  }) async {
    try {
      _state = _state.copyWith(
        isLoading: true,
        error: null,
        filterOwnerId: ownerId,
        filterStatus: status,
      );
      notifyListeners();

      final terrenos = await _firestoreService.listTerrenos(
        ownerId: ownerId,
        status: status,
        limit: _state.pageSize,
      );

      _state = _state.copyWith(
        terrenos: terrenos,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load terrenos: $e',
      );
      notifyListeners();
    }
  }

  /// Get stream of terrenos for real-time updates
  Stream<List<Map<String, dynamic>>> getTerrnosStream({
    String? ownerId,
    String? status,
  }) {
    return _firestoreService
        .getTerrnosStream(
          ownerId: ownerId,
          status: status,
          limit: _state.pageSize,
        )
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  /// Get a specific terreno
  Future<void> getTerreno(String terrenoId) async {
    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      final terreno = await _firestoreService.getTerreno(terrenoId);

      _state = _state.copyWith(
        selectedTerreno: terreno,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to load terreno: $e',
      );
      notifyListeners();
    }
  }

  /// Get stream for a specific terreno
  Stream<DocumentSnapshot<Map<String, dynamic>>> getTerrenoStream(
    String terrenoId,
  ) {
    return _firestoreService.getTerrenoStream(terrenoId);
  }

  /// Create a new terreno
  Future<String?> createTerreno(Map<String, dynamic> data) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final terrenoId = await _firestoreService.createTerreno(data);

      // Reload terrenos
      await loadTerrenos(ownerId: data['ownerId']);

      _state = _state.copyWith(isLoading: false);
      notifyListeners();

      return terrenoId;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to create terreno: $e',
      );
      notifyListeners();
      return null;
    }
  }

  /// Update a terreno
  Future<bool> updateTerreno(
    String terrenoId,
    Map<String, dynamic> data,
  ) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _firestoreService.updateTerreno(terrenoId, data);

      // Update selected terreno
      if (_state.selectedTerreno?['id'] == terrenoId) {
        final updatedTerreno = await _firestoreService.getTerreno(terrenoId);
        _state = _state.copyWith(selectedTerreno: updatedTerreno);
      }

      _state = _state.copyWith(isLoading: false);
      notifyListeners();

      return true;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to update terreno: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// Delete a terreno (soft delete)
  Future<bool> deleteTerreno(String terrenoId) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _firestoreService.deleteTerreno(terrenoId);

      // Remove from list
      _state = _state.copyWith(
        terrenos: _state.terrenos
            .where((t) => t['id'] != terrenoId)
            .toList(),
        isLoading: false,
      );
      notifyListeners();

      return true;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Failed to delete terreno: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// Add terreno to favorites
  Future<bool> addToFavorites(String userId, String terrenoId) async {
    try {
      await _firestoreService.addToFavorites(userId, terrenoId);
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to add to favorites: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove terreno from favorites
  Future<bool> removeFromFavorites(String userId, String terrenoId) async {
    try {
      await _firestoreService.removeFromFavorites(userId, terrenoId);
      return true;
    } catch (e) {
      _state = _state.copyWith(error: 'Failed to remove from favorites: $e');
      notifyListeners();
      return false;
    }
  }

  /// Get favorites stream
  Stream<List<Map<String, dynamic>>> getFavoritesStream(String userId) {
    return _firestoreService
        .getFavoritesStream(userId)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  /// Clear selected terreno
  void clearSelected() {
    _state = _state.copyWith(selectedTerreno: null);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  /// Set page size for pagination
  void setPageSize(int pageSize) {
    _state = _state.copyWith(pageSize: pageSize);
  }
}
