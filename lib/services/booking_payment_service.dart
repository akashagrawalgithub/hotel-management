import 'dart:async';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// ---------------------------------------------------------------------------
/// CLIENT INTERFACE → You can hot swap Dio / Http / Chopper / Anything
/// ---------------------------------------------------------------------------
abstract class ApiClient {
  Future<dynamic> get(String url);
  Future<dynamic> post(String url, Map<String, dynamic> body);
}

/// ---------------------------------------------------------------------------
/// BOOKING PAYMENT SERVICE
/// ---------------------------------------------------------------------------
class BookingPaymentService {
  final ApiClient client;
  final String baseUrl;

  late Razorpay _razorpay;

  BookingPaymentService({
    required this.client,
    required this.baseUrl,
  }) {
    _razorpay = Razorpay();
  }

  /// -------------------------------------------------------------------------
  /// PUBLIC FLOW METHOD
  /// -------------------------------------------------------------------------
  Future<Map<String, dynamic>> startBookingPayment({
    required Map<String, dynamic> bookingBody,
    required BuildContext context,
  }) async {
    Map<String, dynamic>? bookingData;
    Map<String, dynamic>? orderData;
    String? razorpayKey;

    try {
      /// STEP 1 → CREATE BOOKING
      final bookingRes = await createBooking(bookingBody);

      bookingData = bookingRes;

      final bookingId = bookingRes["bookingId"];
      final amount = bookingRes["pricing"]["totalAmount"];

      /// STEP 2 → GET RAZORPAY KEY
      razorpayKey = await getRazorpayKey();

      /// STEP 3 → CREATE ORDER
      final order = await createOrder(
        bookingId: bookingId,
        amount: amount,
      );
      orderData = order;

      /// STEP 4 → OPEN RAZORPAY
      final paymentResult = await _openRazorpay(
        razorpayKey: razorpayKey,
        orderId: order["id"],
        amount: order["amount"],
        bookingId: bookingId,
      );

      return {
        "status": "success",
        "booking": bookingData,
        "order": orderData,
        "razorpay": paymentResult,
      };
    } catch (e) {
      return {
        "status": "cancelled",
        "booking": bookingData,
        "order": orderData,
        "error": e.toString(),
      };
    }
  }

  /// -------------------------------------------------------------------------
  /// CREATE BOOKING
  /// -------------------------------------------------------------------------
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> body) async {
    final res = await client.post(
      "$baseUrl/api/bookings/book-now",
      body,
    );
    if (res["success"] != true) throw "Booking Failed";

    return {
      "bookingId": res["data"]["bookingId"],
      "booking": res["data"]["booking"],
      "pricing": res["data"]["pricing"],
    };
  }

  /// -------------------------------------------------------------------------
  /// GET RAZORPAY KEY
  /// -------------------------------------------------------------------------
  Future<String> getRazorpayKey() async {
    final res = await client.get("$baseUrl/api/payments/key");
    return res["key"];
  }

  /// -------------------------------------------------------------------------
  /// CREATE ORDER IN BACKEND
  /// -------------------------------------------------------------------------
  Future<Map<String, dynamic>> createOrder({
    required String bookingId,
    required num amount,
  }) async {
    final res = await client.post(
      "$baseUrl/api/payments/create-order",
      {
        "bookingId": bookingId,
        "amount": amount,
      },
    );

    if (res["order"] == null) throw "Order creation failed";

    return res["order"];
  }

  /// -------------------------------------------------------------------------
  /// INTERNAL: RAZORPAY PAYMENT
  /// -------------------------------------------------------------------------
  Future<Map<String, dynamic>> _openRazorpay({
    required String razorpayKey,
    required String orderId,
    required num amount,
    required String bookingId,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      completer.complete({
        "paymentId": r.paymentId,
        "orderId": r.orderId,
        "signature": r.signature,
      });
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      completer.completeError("User Cancelled / Failed: ${r.message}");
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      // Optional use
    });

    var options = {
      "key": razorpayKey,
      "amount": amount, // already in paisa from backend (330000)
      "currency": "INR",
      "name": "Flashrooms",
      "description": "Booking ID: $bookingId",
      "order_id": orderId,
      "theme": {
        "color": "#E70F0F" // your red color
      },
      "image":
          "https://flashrooms.in/wp-content/uploads/2024/03/Black-and-White-Minimalist-Professional-Initial-Logo-2-1.png", // replace with your logo URL
      "prefill": {
        "contact": "",
        "email": "",
      }
    };

    _razorpay.open(options);
    return completer.future;
  }

  void dispose() {
    _razorpay.clear();
  }
}
