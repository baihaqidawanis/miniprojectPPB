import 'dart:io';
import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'package:path/path.dart' as path;

class StorageService {
  late Minio _minio;
  final String _bucketName = 'miniproject-pbb';

  StorageService() {
    _minio = Minio(
      endPoint: '192.168.10.135',
      port: 9000,
      useSSL: false,
      accessKey: 'adminadmin',
      secretKey: 'password123',
    );
  }

  String _buildUrl(String objectName) {
    final protocol = _minio.useSSL ? 'https' : 'http';
    final portStr = (_minio.port == 80 || _minio.port == 443) ? '' : ':${_minio.port}';
    return '$protocol://${_minio.endPoint}$portStr/$_bucketName/$objectName';
  }

  Future<String?> _upload(File imageFile, String objectName) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final stream = Stream.value(Uint8List.fromList(bytes));
      await _minio.putObject(_bucketName, objectName, stream, size: bytes.length);
      return _buildUrl(objectName);
    } catch (e) {
      print('[StorageService] Error upload: $e');
      return null;
    }
  }

  Future<String?> uploadTeamPhoto(File imageFile, String matchId, String teamType) async {
    final ext = path.extension(imageFile.path);
    return _upload(imageFile, 'matches/$matchId/${teamType}_logo$ext');
  }

  Future<String?> uploadProfilePhoto(File imageFile, String userId) async {
    final ext = path.extension(imageFile.path);
    return _upload(imageFile, 'profiles/$userId/avatar$ext');
  }

  Future<String?> uploadStartingXiPhoto(File imageFile, String matchId, String teamType) async {
    final ext = path.extension(imageFile.path);
    return _upload(imageFile, 'matches/$matchId/${teamType}_xi$ext');
  }

  Future<String?> uploadNewsPhoto(File imageFile, String newsId) async {
    final ext = path.extension(imageFile.path);
    return _upload(imageFile, 'news/$newsId/cover$ext');
  }

  Future<void> deleteByUrl(String publicUrl) async {
    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;
      if (segments.length < 2) return;
      final objectName = segments.sublist(1).join('/');
      await _minio.removeObject(_bucketName, objectName);
    } catch (e) {
      print('[StorageService] Error hapus dari MinIO: $e');
    }
  }
}
