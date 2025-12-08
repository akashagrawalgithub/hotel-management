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

  // Get notifications for user
  static Future<Response> getNotifications(String userId) async {
    try {
      _setupInterceptors();
      final response = await _dio.get('/notification/$userId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get all FAQs
  static Future<Response> getFAQs() async {
    try {
      _setupInterceptors();
      final response = await _dio.get('/faq/all');
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

  // Get booking history by email
  static Future<Response> getBookingHistory(String email) async {
    try {
      _setupInterceptors();
      final response = await _dio.get(
        '/bookings/booking-history',
        queryParameters: {'email': email},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get hotel rooms by hotel ID
  static Future<Response> getHotelRooms(String hotelId) async {
    try {
      _setupInterceptors();
      final response = await _dio.get('/room/get-hotel-rooms/$hotelId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get all rooms with filters
  static Future<Response> getAllRooms({
    String? city,
    int? adults,
    int? children,
    String? startDate,
    String? endDate,
  }) async {
    try {
      _setupInterceptors();
      final queryParams = <String, dynamic>{};
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (adults != null) {
        queryParams['adults'] = adults;
      }
      if (children != null) {
        queryParams['children'] = children;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      final response = await _dio.get('/room/get-all-rooms', queryParameters: queryParams);
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

  // Create inquiry/contact form submission
  static Future<Response> createInquiry({
    required String name,
    required String email,
    required String phone,
    required String message,
    String source = 'contact',
  }) async {
    try {
      _setupInterceptors();
      final response = await _dio.post(
        '/inquiries/create',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'message': message,
          'source': source,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Search hotels by query
  static Future<Response> searchHotels(String query) async {
    try {
      _setupInterceptors();
      final response = await _dio.get(
        '/hotel/search',
        queryParameters: {'query': query},
      );
      return response;
    } catch (e) {
      if (e is DioException) {
        // Handle Dio errors
        if (e.response != null) {
          // Server responded with error status
          throw Exception('Search failed: ${e.response?.statusCode} - ${e.response?.data}');
        } else {
          // Network or other error
          throw Exception('Network error: ${e.message}');
        }
      }
      rethrow;
    }
  }

  // Get favorites list by userId
  static Future<Response> getFavorites(String userId) async {
    try {
      _setupInterceptors();
      final response = await _dio.get(
        '/auth/favorite/list',
        queryParameters: {'userId': userId},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Add to favorites
  static Future<Response> addToFavorites(String userId, String itemId) async {
    try {
      _setupInterceptors();
      final response = await _dio.post(
        '/auth/favorite/add',
        data: {
          'userId': userId,
          'itemId': itemId,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Remove from favorites
  static Future<Response> removeFromFavorites(String userId, String itemId) async {
    try {
      _setupInterceptors();
      final response = await _dio.post(
        '/auth/favorite/remove',
        data: {
          'userId': userId,
          'itemId': itemId,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get hotel by ID - fetches all hotels and filters by ID
  static Future<Response> getHotelById(String hotelId) async {
    try {
      _setupInterceptors();
      // Try specific endpoint first
      try {
        final response = await _dio.get('/hotel/get-hotel/$hotelId');
        return response;
      } catch (_) {
        // Fallback: get all hotels and filter
        final allHotelsResponse = await getHotels();
        if (allHotelsResponse.data != null && allHotelsResponse.data is List) {
          final hotels = allHotelsResponse.data as List;
          final hotel = hotels.firstWhere(
            (h) => (h['_id'] ?? h['id']).toString() == hotelId,
          );
          // Create a new response with the hotel data
          return Response(
            requestOptions: allHotelsResponse.requestOptions,
            data: hotel,
            statusCode: 200,
            statusMessage: 'OK',
            headers: allHotelsResponse.headers,
            isRedirect: false,
            redirects: [],
            extra: allHotelsResponse.extra,
          );
        }
        throw Exception('Hotel not found');
      }
    } catch (e) {
      rethrow;
    }
  }
}
