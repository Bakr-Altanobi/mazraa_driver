import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/api_exception.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';

class ApiClient {
  ApiClient(this._store, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await _store.read();
          if (session != null && !options.path.contains('api/Auth/')) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final shouldRefresh =
              error.response?.statusCode == 401 &&
              request.extra['refreshed'] != true &&
              !request.path.contains('api/Auth/');
          if (!shouldRefresh) return handler.next(error);
          try {
            final session = await _refreshOnce();
            if (session == null) return handler.next(error);
            request.extra['refreshed'] = true;
            request.headers['Authorization'] = 'Bearer ${session.accessToken}';
            handler.resolve(await _dio.fetch<dynamic>(request));
          } catch (_) {
            await _store.clear();
            handler.next(error);
          }
        },
      ),
    );
  }

  final SecureSessionStore _store;
  final Dio _dio;
  Future<AuthSession?>? _refreshing;

  Future<AuthSession?> _refreshOnce() {
    final active = _refreshing;
    if (active != null) return active;
    final future = _refresh();
    _refreshing = future;
    return future.whenComplete(() => _refreshing = null);
  }

  Future<AuthSession?> _refresh() async {
    final current = await _store.read();
    if (current == null) return null;
    final plainDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    final response = await plainDio.post<Map<String, dynamic>>(
      ApiEndpoints.refresh,
      data: {
        'refreshToken': current.refreshToken,
        'deviceName': 'mazraa-driver',
      },
    );
    final next = AuthSession.fromJson(response.data ?? const {});
    if (!next.isUsable) return null;
    await _store.write(next);
    return next;
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (error, stack) {
      if (kDebugMode) debugPrintStack(stackTrace: stack);
      throw ApiException.fromDio(error);
    }
  }

  Future<T> post<T>(String path, {Object? data}) async {
    try {
      final response = await _dio.post<T>(path, data: data);
      return response.data as T;
    } on DioException catch (error, stack) {
      if (kDebugMode) debugPrintStack(stackTrace: stack);
      throw ApiException.fromDio(error);
    }
  }
}
