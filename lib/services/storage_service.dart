import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image (XFile) to a specified folder in Firebase Storage.
  /// Returns the Download URL on success, or throws exception on failure.
  Future<String> uploadImage({required XFile image, required String folder}) async {
    try {
      // Sanitize filename
      final String safeName = image.name.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '');
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final Reference ref = _storage.ref().child('$folder/$fileName');
      
      UploadTask task;
      
      if (kIsWeb) {
        final data = await image.readAsBytes();
        task = ref.putData(data, SettableMetadata(contentType: image.mimeType));
      } else {
        task = ref.putFile(File(image.path));
      }

      final TaskSnapshot snapshot = await task;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
      
    } catch (e) {
      print('Storage Error: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Deletes an image from storage given its URL.
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
       print('Error deleting image: $e');
       // Don't throw, just log. Image might be already gone.
    }
  }
}
