import 'dart:io';
import 'package:http/http.dart' as http;
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

  static Future<void> uploadFileToS3(String presignedUrl, File file) async {
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: {
        'Content-Type': 'application/octet-stream',
      },
      body: stream,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to upload file to S3');
    }
  }

  static Future<http.Response> downloadFileFromS3(String presignedUrl) async {
    final response = await http.get(Uri.parse(presignedUrl));
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to download file from S3');
    }
  }
}

