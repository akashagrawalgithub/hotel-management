import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _baseUrl = 'https://hotel-backend-vgct.onrender.com';

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

  // Initialize Dio with interceptors for token management
  static void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to headers if available
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 unauthorized - token expired
          if (error.response?.statusCode == 401) {
            await clearToken();
            // You can navigate to login page here
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Save auth token securely
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get auth token from secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Clear auth token
  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Login API call
  static Future<Response> login(String email, String password) async {
    try {
      _setupInterceptors();
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      // Save token if login successful
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Register API call
  static Future<Response> register(Map<String, dynamic> userData) async {
    try {
      _setupInterceptors();
      final response = await _dio.post(
        '/register',
        data: userData,
      );
      
      // Save token if registration successful
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  static Future<void> logout() async {
    await clearToken();
  }

  // Generic GET request
  static Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
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

