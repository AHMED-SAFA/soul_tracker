import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import '../config/cloudinary_config.dart';

class MediaService {
  final ImagePicker _imagePicker = ImagePicker();
  static String get _cloudName => CloudinaryConfig.cloudName;
  static String get _apiKey => CloudinaryConfig.apiKey;
  static String get _apiSecret => CloudinaryConfig.apiSecret;
  static String get _folderName => CloudinaryConfig.profileImageFolder;

  MediaService();

  Future<File?> getImageFromGallery() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null) return File(file.path);
    return null;
  }

  Future<File?> getImageFromCamera() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null) return File(file.path);
    return null;
  }

  Future<String> uploadProfileImageToCloudinary(
    File image,
    String emailId,
  ) async {
    try {
      // Generate timestamp for signature
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Create public_id with folder structure
      final publicId = '$_folderName/$emailId-${timestamp}';

      // Create signature
      final signature = _generateSignature(
        publicId: publicId,
        timestamp: timestamp,
      );

      // Create multipart request
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields.addAll({
        'api_key': _apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'public_id': publicId,
        'folder': _folderName,
        'transformation': 'c_fill,w_300,h_300,q_auto,f_auto', // Optimize image
        'resource_type': 'image',
      });

      // Add image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        image.path,
        filename: p.basename(image.path),
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['secure_url'] as String;
      } else {
        print(
          'Cloudinary upload error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to upload image to Cloudinary: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<bool> deleteImageFromCloudinary(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final signature = _generateDeleteSignature(
        publicId: publicId,
        timestamp: timestamp,
      );

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'api_key': _apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'public_id': publicId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['result'] == 'ok';
      } else {
        print(
          'Cloudinary delete error: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  String _generateSignature({
    required String publicId,
    required String timestamp,
  }) {
    final params = <String, String>{
      'public_id': publicId,
      'timestamp': timestamp,
      'folder': _folderName,
      'transformation': 'c_fill,w_300,h_300,q_auto,f_auto',
    };

    // Sort parameters alphabetically
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Create parameter string
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Create string to sign
    final stringToSign = '$paramString$_apiSecret';

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  String _generateDeleteSignature({
    required String publicId,
    required String timestamp,
  }) {
    final params = <String, String>{
      'public_id': publicId,
      'timestamp': timestamp,
    };

    // Sort parameters alphabetically
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Create parameter string
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Create string to sign
    final stringToSign = '$paramString$_apiSecret';

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  // Utility method to extract public_id from Cloudinary URL
  String? extractPublicIdFromUrl(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;

      // Find the segment after 'upload' or 'image/upload'
      int uploadIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'upload') {
          uploadIndex = i;
          break;
        }
      }

      if (uploadIndex != -1 && uploadIndex + 2 < pathSegments.length) {
        // Skip version if present (starts with 'v')
        int startIndex = uploadIndex + 1;
        if (pathSegments[startIndex].startsWith('v') &&
            pathSegments[startIndex].length > 1 &&
            int.tryParse(pathSegments[startIndex].substring(1)) != null) {
          startIndex++;
        }

        // Join remaining segments and remove file extension
        final publicIdWithExt = pathSegments.sublist(startIndex).join('/');
        final lastDotIndex = publicIdWithExt.lastIndexOf('.');
        if (lastDotIndex != -1) {
          return publicIdWithExt.substring(0, lastDotIndex);
        }
        return publicIdWithExt;
      }
    } catch (e) {
      print('Error extracting public_id: $e');
    }
    return null;
  }

  // Show image picker options with dialog
  Future<File?> showImagePickerOptions() async {
    // This method can be used with a BuildContext to show a dialog
    // For now, returning gallery picker as default
    return await getImageFromGallery();
  }

  // Show image picker dialog with context
  Future<File?> showImagePickerDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await getImageFromGallery();
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await getImageFromCamera();
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
