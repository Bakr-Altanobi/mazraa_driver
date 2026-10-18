import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final driverMediaApiProvider = Provider<DriverMediaApi>(
  (ref) => DriverMediaApi(ref.watch(apiClientProvider)),
);

class DriverMediaApi {
  const DriverMediaApi(this._client);

  static const driverDocumentImageType = 11;
  final ApiClient _client;

  Future<String> uploadDriverDocument({
    required String filePath,
    required int driverId,
  }) async {
    final filename = filePath.split(RegExp(r'[/\\]')).last;
    final form = FormData.fromMap({
      'File': await MultipartFile.fromFile(filePath, filename: filename),
      'Type': driverDocumentImageType,
      'EntityId': driverId,
    });
    final json = await _client.postForm<Map<String, dynamic>>(
      'api/Images/upload',
      form,
    );
    final url = (json['imageUrl'] ?? json['ImageUrl'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw const FormatException('السيرفر لم يُرجع رابط الصورة بعد الرفع.');
    }
    return url;
  }
}
