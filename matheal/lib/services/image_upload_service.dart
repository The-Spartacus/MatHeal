import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  final String? _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
  final String? _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

  /// Uploads the given image file to Cloudinary and returns the secure URL.
  Future<String> uploadImage(File imageFile) async {
    if (_cloudName == null || _uploadPreset == null) {
      throw Exception('Cloudinary environment variables not set in .env file.');
    }

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset!
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = json.decode(responseString);
        debugPrint('Cloudinary Response: $jsonMap');
        return jsonMap['secure_url'];
      } else {
        throw Exception('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }
}

