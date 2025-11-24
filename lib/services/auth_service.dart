import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userFirstNameKey = 'user_first_name';
  static const _userLastNameKey = 'user_last_name';
  static const _userPhoneKey = 'user_phone';
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
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
          }
          return handler.next(error);
        },
      ),
    );
    _interceptorsInitialized = true;
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

  // Save user data
  static Future<void> saveUserData({
    required String userId,
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Get user name
  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  // Get user first name
  static Future<String?> getUserFirstName() async {
    return await _storage.read(key: _userFirstNameKey);
  }

  // Get user last name
  static Future<String?> getUserLastName() async {
    return await _storage.read(key: _userLastNameKey);
  }

  // Get user phone
  static Future<String?> getUserPhone() async {
    return await _storage.read(key: _userPhoneKey);
  }

  // Save additional user info
  static Future<void> saveAdditionalUserInfo({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    if (firstName != null) {
      await _storage.write(key: _userFirstNameKey, value: firstName);
    }
    if (lastName != null) {
      await _storage.write(key: _userLastNameKey, value: lastName);
    }
    if (phone != null) {
      await _storage.write(key: _userPhoneKey, value: phone);
    }
  }

  // Clear user data
  static Future<void> clearUserData() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userFirstNameKey);
    await _storage.delete(key: _userLastNameKey);
    await _storage.delete(key: _userPhoneKey);
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Signup API call
  static Future<Response> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      _setupInterceptors();
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }

      if (response.data['user'] != null) {
        final user = response.data['user'];
        await saveUserData(
          userId: user['_id'] ?? '',
          name: user['name'] ?? '',
          email: user['email'] ?? '',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login API call
  static Future<Response> login(String email, String password) async {
    try {
      _setupInterceptors();
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }

      if (response.data['user'] != null) {
        final user = response.data['user'];
        await saveUserData(
          userId: user['_id'] ?? '',
          name: user['name'] ?? '',
          email: user['email'] ?? '',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update User API call
  static Future<Response> updateUser(
    String userId, {
    String? name,
    String? email,
    String? password,
  }) async {
    try {
      _setupInterceptors();
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (password != null) data['password'] = password;

      final response = await _dio.put('/auth/update/$userId', data: data);

      if (response.data['user'] != null) {
        final user = response.data['user'];
        await saveUserData(
          userId: user['_id'] ?? userId,
          name: user['name'] ?? name ?? '',
          email: user['email'] ?? email ?? '',
        );
      } else {
        final currentName = await getUserName();
        final currentEmail = await getUserEmail();
        await saveUserData(
          userId: userId,
          name: name ?? currentName ?? '',
          email: email ?? currentEmail ?? '',
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout API call
  static Future<Response> logout() async {
    try {
      _setupInterceptors();
      final response = await _dio.post('/auth/logout');
      await clearToken();
      await clearUserData();
      return response;
    } catch (e) {
      await clearToken();
      await clearUserData();
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
