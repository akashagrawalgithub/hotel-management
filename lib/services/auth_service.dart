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
      validateStatus: (status) {
        // Don't throw exception for status codes < 500
        return status! < 500;
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
          // Handle 400 errors with better messages
          if (error.response?.statusCode == 400) {
            final isLoginRequest = error.requestOptions.path.contains('/login');
            final errorMessage = _extractErrorMessage(error.response?.data, isLogin: isLoginRequest);
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                error: errorMessage,
              ),
            );
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
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }

  // Extract error message from response
  static String _extractErrorMessage(dynamic responseData, {bool isLogin = false}) {
    if (responseData == null) return 'An error occurred';
    
    if (responseData is Map) {
      String? message;
      
      // Try common error message fields
      if (responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (responseData['error'] != null) {
        message = responseData['error'].toString();
      } else if (responseData['msg'] != null) {
        message = responseData['msg'].toString();
      }
      
      // For login errors, show user-friendly message
      if (isLogin && message != null) {
        if (message.toLowerCase().contains('User not found') || 
            message.toLowerCase().contains('invalid') ||
            message.toLowerCase().contains('incorrect')) {
          return 'Wrong email or Password';
        }
      }
      
      if (message != null) {
        return message;
      }
      
      // Check for validation errors
      if (responseData['errors'] != null) {
        final errors = responseData['errors'];
        if (errors is Map) {
          final errorList = errors.values.expand((e) => e is List ? e : [e]).toList();
          return errorList.join(', ');
        }
      }
    }
    
    return 'Bad request. Please check your input and try again.';
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

      // Check for error status codes
      if (response.statusCode == 400) {
        final errorMessage = _extractErrorMessage(response.data);
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/signup'),
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }

      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }

      if (response.data['user'] != null) {
        final user = response.data['user'];
        await saveUserData(
          userId: user['_id']?.toString() ?? '',
          name: user['name']?.toString() ?? user['username']?.toString() ?? '',
          email: user['email']?.toString() ?? '',
        );
      }

      return response;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        final errorMessage = _extractErrorMessage(e.response?.data);
        throw Exception(errorMessage);
      }
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

      // Check for error status codes
      if (response.statusCode == 400) {
        final errorMessage = _extractErrorMessage(response.data, isLogin: true);
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }

      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }

      if (response.data['user'] != null) {
        final user = response.data['user'];
        await saveUserData(
          userId: user['_id']?.toString() ?? '',
          name: user['name']?.toString() ?? user['username']?.toString() ?? '',
          email: user['email']?.toString() ?? '',
        );
      }

      return response;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        final errorMessage = _extractErrorMessage(e.response?.data);
        throw Exception(errorMessage);
      }
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

  // Change Password API call
  static Future<Response> changePassword(String userId, String password) async {
    try {
      _setupInterceptors();
      final response = await _dio.put(
        '/auth/change-password/$userId',
        data: {'password': password},
      );
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
