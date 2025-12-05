import 'package:dio/dio.dart';

import '../services/auth_service.dart';
import '../services/booking_payment_service.dart';
// <-- the interface

class DioClientImpl implements ApiClient {
  static const String _baseUrl = 'https://hotel-backend-vgct.onrender.com/api';

  late final Dio _dio;
  static bool _interceptorsInitialized = false;

  DioClientImpl() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  // ---------------------------------------------------------------------------
  // INTERCEPTORS
  // ---------------------------------------------------------------------------
  void _setupInterceptors() {
    if (_interceptorsInitialized) return;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await AuthService.clearToken();
          }
          return handler.next(error);
        },
      ),
    );

    _interceptorsInitialized = true;
  }

  // ---------------------------------------------------------------------------
  // IMPLEMENTATION OF ApiClient INTERFACE
  // ---------------------------------------------------------------------------

  @override
  Future<dynamic> get(String url) async {
    try {
      final res = await _dio.get(url);
      return res.data;
    } on DioError catch (e) {
      throw e.response?.data ?? e.message;
    }
  }

  @override
  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(url, data: body);
      return res.data;
    } on DioError catch (e) {
      throw e.response?.data ?? e.message;
    }
  }
}
