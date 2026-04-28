import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Firebase Storage Service - Image and file upload/download
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload terreno image
  Future<String> uploadTerrenoImage({
    required String terrenoId,
    required File file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child(
            'terrenos/$terrenoId/$fileName',
          );

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      logger.i('Image uploaded: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      logger.e('Firebase storage error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Upload user profile image
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child(
            'users/$userId/profile.jpg',
          );

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      logger.i('Profile image uploaded: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      logger.e('Firebase storage error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Upload multiple terreno images
  Future<List<String>> uploadTerrenoImages({
    required String terrenoId,
    required List<File> files,
  }) async {
    try {
      final downloadUrls = <String>[];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = 'image_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final ref = _storage.ref().child(
              'terrenos/$terrenoId/$fileName',
            );

        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      logger.i('Images uploaded: ${downloadUrls.length}');
      return downloadUrls;
    } on FirebaseException catch (e) {
      logger.e('Firebase storage error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Delete terreno image
  Future<void> deleteTerrenoImage({
    required String terrenoId,
    required String fileName,
  }) async {
    try {
      await _storage.ref().child('terrenos/$terrenoId/$fileName').delete();
      logger.i('Image deleted: terrenos/$terrenoId/$fileName');
    } on FirebaseException catch (e) {
      logger.e('Failed to delete image: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Get download URL for an image
  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } on FirebaseException catch (e) {
      logger.e('Failed to get download URL: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Monitor upload progress
  UploadTask uploadTerrenoImageWithProgress({
    required String terrenoId,
    required File file,
    required String fileName,
  }) {
    final ref = _storage.ref().child(
          'terrenos/$terrenoId/$fileName',
        );

    return ref.putFile(file);
  }

  /// Delete all terreno images
  Future<void> deleteTerrenoFolder(String terrenoId) async {
    try {
      final ref = _storage.ref().child('terrenos/$terrenoId');
      await ref.delete();
      logger.i('Terreno folder deleted: $terrenoId');
    } on FirebaseException catch (e) {
      // Folder might not exist, which is fine
      if (e.code != 'object-not-found') {
        logger.e('Failed to delete terreno folder: ${e.code} - ${e.message}');
        rethrow;
      }
    }
  }
}
