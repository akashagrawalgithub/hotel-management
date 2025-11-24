import 'package:dio/dio.dart';
import 'auth_service.dart';

class HotelService {
  static const _baseUrl = 'https://hotel-backend-vgct.onrender.com/api';

  static final Dio _dio = Dio(
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

  static bool _interceptorsInitialized = false;

  // Initialize Dio with interceptors for token management
  static void _setupInterceptors() {
    if (_interceptorsInitialized) return;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getToken();
          if (token != null) {
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

  // Get random hotels
  static Future<Response> getRandomHotels() async {
    try {
      _setupInterceptors();
      final response = await _dio.get('/hotel/get-random');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get all hotels
  static Future<Response> getHotels() async {
    try {
      _setupInterceptors();
      final response = await _dio.get('/hotel/get-hotels');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Generic GET request
  static Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      _setupInterceptors();
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Generic POST request
  static Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      _setupInterceptors();
      return await _dio.post(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Generic PUT request
  static Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      _setupInterceptors();
      return await _dio.put(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Generic DELETE request
  static Future<Response> delete(String endpoint) async {
    try {
      _setupInterceptors();
      return await _dio.delete(endpoint);
    } catch (e) {
      rethrow;
    }
  }
}
