import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';

/// Configured Dio instance for talking to the Kitchen Key backend.
Dio createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}',
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    contentType: Headers.jsonContentType, // send POST bodies as JSON
    headers: {'Accept': 'application/json'},
  ));
  // Lightweight logging in debug.
  assert(() {
    dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      responseHeader: false,
      requestBody: true,
      responseBody: false,
    ));
    return true;
  }());
  return dio;
}

final dioProvider = Provider<Dio>((ref) => createDio());

/// A user-friendly message for a Dio failure (used by error states in the UI).
String describeApiError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server took too long to respond.';
      case DioExceptionType.connectionError:
        return "Can't reach the server. Check it's running and the address in api_config.dart.";
      case DioExceptionType.badResponse:
        return 'Server error (${error.response?.statusCode}).';
      default:
        return 'Network error. Please try again.';
    }
  }
  return 'Something went wrong.';
}
