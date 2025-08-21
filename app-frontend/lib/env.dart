import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for environment-specific configuration.
class EnvConfig {
  EnvConfig._();

  /// Base URL for backend API (no trailing slash).
  static String get apiBaseUrl {
    if (kIsWeb) {
      // When running Flutter web locally, backend assumed to run on localhost:8080
      return 'http://localhost:8080';
    }
    // Android emulator maps host loopback to 10.0.2.2
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    // iOS simulator & desktop can usually use localhost directly
    return 'http://localhost:8080';
  }
}

