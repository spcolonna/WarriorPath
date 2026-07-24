import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Comprime una imagen (resize + WebP) y la sube a Firebase Storage.
  ///
  /// [storagePath] es el path dentro del bucket SIN extensión (se agrega
  /// `.webp` automáticamente, o `.jpg` si la compresión falla).
  /// [maxDimension] limita el lado más grande de la imagen — de sobra para
  /// avatares/logos que se muestran chicos, y reduce mucho el peso subido.
  Future<String> uploadImage(
    File imageFile,
    String storagePath, {
    int maxDimension = 800,
    int quality = 80,
  }) async {
    Uint8List? compressed;
    try {
      compressed = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.webp,
      );
    } catch (e) {
      print('Error al comprimir imagen: $e');
    }

    try {
      if (compressed != null) {
        final ref = _storage.ref('$storagePath.webp');
        await ref.putData(
          compressed,
          SettableMetadata(contentType: 'image/webp'),
        );
        return await ref.getDownloadURL();
      }
      // Fallback: si la compresión falla, subimos el original sin tocar.
      final ref = _storage.ref('$storagePath.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      throw Exception('No se pudo subir la imagen.');
    }
  }
}
