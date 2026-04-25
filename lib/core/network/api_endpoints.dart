import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl {
    final env = dotenv.env['ENVIRONMENT'] ?? 'development';
    
    if (env == 'production') {
      return dotenv.env['API_BASE_URL_PRODUCTION'] ?? '';
    }

    if (Platform.isAndroid) {
      return dotenv.env['API_BASE_URL_ANDROID'] ?? 'http://10.0.2.2:3000/api/client/auth';
    } else {
      return dotenv.env['API_BASE_URL_IOS'] ?? 'http://localhost:3000/api/client/auth';
    }
  }

  static const String sendOtp = '/send-otp';
  static const String verifyOtp = '/verify-otp';
  static const String logout = '/logout';
  static const String refresh = '/refresh';
}
