import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../env.dart';

class MediaUploadResult {
  final String key;
  final String url; // public URL
  MediaUploadResult(this.key, this.url);
}

class MediaUploadService {
  MediaUploadService._();
  static final MediaUploadService instance = MediaUploadService._();
  final _uuid = const Uuid();

  Future<MediaUploadResult> uploadFile(File file, {required String folder}) async {
    final ext = file.path.split('.').last.toLowerCase();
    final key = '$folder/${_uuid.v4()}.$ext';
    final presignUri = Uri.parse('${EnvConfig.apiBaseUrl}/api/s3/presign-upload').replace(queryParameters: {'key': key});
    final presignRes = await http.get(presignUri);
    if (presignRes.statusCode != 200) {
      throw Exception('Failed presign');
    }
    final putUrl = presignRes.body.replaceAll('"', '');
    final bytes = await file.readAsBytes();
    final putRes = await http.put(Uri.parse(putUrl), body: bytes, headers: {
      'Content-Length': bytes.length.toString(),
    });
    if (putRes.statusCode != 200 && putRes.statusCode != 201) {
      throw Exception('Upload failed: ${putRes.statusCode}');
    }
    final publicUrl = 'https://${EnvConfig.s3Bucket}.s3.${EnvConfig.s3Region}.amazonaws.com/$key';
    return MediaUploadResult(key, publicUrl);
  }
}
