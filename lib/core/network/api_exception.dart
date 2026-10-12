import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isOffline = false});

  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? serverMessage;
    if (data is String && data.trim().isNotEmpty) {
      serverMessage = data;
    } else if (data is Map) {
      serverMessage = (data['message'] ?? data['title'] ?? data['error'])
          ?.toString();
    }
    final offline =
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.unknown;
    return ApiException(
      serverMessage ?? _defaultMessage(status, offline),
      statusCode: status,
      isOffline: offline,
    );
  }

  final String message;
  final int? statusCode;
  final bool isOffline;

  static String _defaultMessage(int? status, bool offline) {
    if (offline) return 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجددًا.';
    return switch (status) {
      400 => 'البيانات المرسلة غير صحيحة.',
      401 => 'انتهت الجلسة. سجّل الدخول من جديد.',
      403 => 'ليست لديك صلاحية لتنفيذ هذه العملية.',
      404 => 'العنصر المطلوب غير موجود.',
      409 => 'تغيّرت حالة العملية على الخادم. حدّث البيانات وحاول مجددًا.',
      422 => 'تعذر التحقق من البيانات المدخلة.',
      429 => 'طلبات كثيرة خلال وقت قصير. حاول لاحقًا.',
      500 => 'حدث خطأ في الخادم.',
      503 => 'الخدمة غير متاحة مؤقتًا.',
      _ => 'تعذر إكمال العملية الآن.',
    };
  }

  @override
  String toString() => message;
}
