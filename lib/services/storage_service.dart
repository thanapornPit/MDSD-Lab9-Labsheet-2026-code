import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    final extension = path.extension(imageFile.path);
    final fileExtension = extension.isEmpty ? '.jpg' : extension;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${sellerId}_$timestamp$fileExtension';
    final imageRef = _storage.ref().child('listing_images/$sellerId/$fileName');

    await imageRef.putFile(imageFile).timeout(const Duration(seconds: 15));
    final downloadUrl = await imageRef.getDownloadURL();
    return downloadUrl;
  }
}
