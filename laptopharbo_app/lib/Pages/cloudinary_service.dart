import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // 🛠️ Replace these with your actual Cloudinary credentials
  static const String cloudName = "djf0nppav"; // 👈 YOUR CLOUD NAME
  static const String uploadPreset = "ECOMApp"; // 👈 YOUR UPLOAD PRESET

  static Future<String> uploadImage(
      Uint8List fileBytes, String fileName) async {
    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final result = jsonDecode(responseBody);

    if (response.statusCode != 200) {
      throw Exception(
          "❌ Cloudinary upload failed: ${result['error']['message']}");
    }

    return result['secure_url']; // ✅ Return uploaded image URL
  }
}
