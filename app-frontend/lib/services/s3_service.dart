import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../env.dart';

class S3Service {
  static Future<String> getPresignedUploadUrl(String key) async {
    final String base = EnvConfig.apiBaseUrl;
    final response = await http.get(Uri.parse('$base/api/s3/presign-upload?key=$key'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to get presigned upload URL');
    }
  }

  static Future<String> getPresignedDownloadUrl(String key) async {
    final String base = EnvConfig.apiBaseUrl;
    final response = await http.get(Uri.parse('$base/api/s3/presign-download?key=$key'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to get presigned download URL');
    }
  }

  static Future<void> uploadFileToS3(String presignedUrl, dynamic fileOrBytes) async {
    try {
      final isWeb = kIsWeb;
      final headers = isWeb ? <String, String>{} : {'Content-Type': 'application/octet-stream'};
      final body = isWeb ? fileOrBytes : http.ByteStream(fileOrBytes.openRead());
      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: headers,
        body: body,
      );
      if (response.statusCode != 200) {
        print('S3 upload failed: status=[31m[1m[4m[7m[5m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m[0m');
        print('Response body: \\${response.body}');
        throw Exception('Failed to upload file to S3: Status: \\${response.statusCode}\\nBody: \\${response.body}');
      }
    } catch (e, st) {
      print('Exception during S3 upload: $e');
      print('Stacktrace: $st');
      rethrow;
    }
  }

  static Future<void> uploadBytesToS3(String presignedUrl, List<int> bytes) async {
    // On web, do not set Content-Type header to avoid S3 signature mismatch
    final headers = kIsWeb ? <String, String>{} : {'Content-Type': 'application/octet-stream'};
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: headers,
      body: bytes,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to upload file to S3: Status: \\${response.statusCode}\\nBody: \\${response.body}');
    }
  }

  static Future<http.Response> downloadFileFromS3(String presignedUrl) async {
    final response = await http.get(Uri.parse(presignedUrl));
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to download file from S3: Status: \\${response.statusCode}\\nBody: \\${response.body}');
    }
  }
}
