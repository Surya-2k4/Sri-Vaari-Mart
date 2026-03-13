import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Use environment variables for better security
  static const String _cloudName =
      "dya8gejqw"; // The user might need to change this
  static const String _uploadPreset =
      "Sri-Vaari-Furnitures"; // The user might need to change this

  static Future<String?> uploadImage(File file) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['secure_url'] as String?;
      } else {
        final errorResponse = await response.stream.bytesToString();
        print('Cloudinary Upload Failed: $errorResponse');
        return null;
      }
    } catch (e) {
      print('Cloudinary Error: $e');
      return null;
    }
  }
}
