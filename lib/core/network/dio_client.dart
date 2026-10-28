import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'mock_api_interceptor.dart';
import 'session_expiry.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      contentType: Headers.jsonContentType,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final storage = ref.read(tokenStorageProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read();
        final isPublicAuthRequest =
            options.path.endsWith('/auth/login') ||
            options.path.endsWith('/auth/registro');
        if (token != null && !isPublicAuthRequest) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthenticated =
            error.requestOptions.headers['Authorization'] is String;
        if (error.response?.statusCode == 401 && isAuthenticated) {
          try {
            await storage.clear();
            ref.read(sessionExpiryProvider.notifier).expire();
          } catch (storageError, stackTrace) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: storageError,
                stackTrace: stackTrace,
              ),
            );
            return;
          }
        }
        handler.next(error);
      },
    ),
  );

  if (AppConfig.useMock) dio.interceptors.add(MockApiInterceptor());
  return dio;
});
