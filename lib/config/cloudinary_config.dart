import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryConfig {
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  static final String apiKey = dotenv.env['CLOUDINARY_API_KEY']!;
  static final String apiSecret = dotenv.env['CLOUDINARY_SECRET_KEY']!;

  // Folder configuration
  static const String profileImageFolder = 'map_tracker_dp';

  // Image transformation settings
  static const String profileImageTransformation = 'c_fill,w_300,h_300,q_auto,f_auto';

  // URLs
  static String get uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static String get destroyUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/destroy';

  // Validation
  static bool get isConfigured {
    return cloudName.isNotEmpty &&
        cloudName != 'YOUR_CLOUD_NAME' &&
        apiKey.isNotEmpty &&
        apiKey != 'YOUR_API_KEY' &&
        apiSecret.isNotEmpty &&
        apiSecret != 'YOUR_API_SECRET';
  }
}