import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for environment-specific configuration.
class EnvConfig {
  EnvConfig._();

  /// Base URL for backend API (no trailing slash).
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8081';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    return 'http://localhost:8081';
  }

  static const String s3Bucket = 'gigmes3dev';
  static const String s3Region = 'us-east-1';

  /// Constructs the S3 file URL for a given key.
  static String s3FileUrl(String key) {
    return 'https://$s3Bucket.s3.$s3Region.amazonaws.com/$key';
  }
}
