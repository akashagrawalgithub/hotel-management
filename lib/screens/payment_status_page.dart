import 'package:flutter/material.dart';

import '../constants/payment_states.dart';

class PaymentStatusPage extends StatelessWidget {
  final PaymentState state;
  final Map<String, dynamic>? booking;
  final Map<String, dynamic>? razorpayData;
  final String? reason;

  const PaymentStatusPage({
    super.key,
    required this.state,
    this.booking,
    this.razorpayData,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getUIConfig(state);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildIllustration(config['image']),
                const SizedBox(height: 25),
                Text(
                  config['title'],
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: config['color'],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  config['message'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 25),

                // DETAILS SECTION
                if (razorpayData != null || booking != null || reason != null)
                  _buildInfoCard(),

                const SizedBox(height: 30),
                _buildActionButton(context, config['buttonText']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI CONFIGURATIONS BASED ON PAYMENT STATE
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _getUIConfig(PaymentState state) {
    switch (state) {
      case PaymentState.success:
        return {
          'title': 'Payment Successful',
          'message':
              'Your booking is confirmed. A confirmation email has been sent.',
          'image': 'assets/images/paymentcomplete.png',
          'color': Colors.green,
          'buttonText': 'Go to Home',
        };
      case PaymentState.processing:
        return {
          'title': 'Payment Processing',
          'message': 'Your payment is still being processed. Please wait.',
          'image': 'assets/images/paymentprocessing.png',
          'color': Colors.orange,
          'buttonText': 'Refresh Status',
        };
      case PaymentState.failed:
        return {
          'title': 'Payment Failed',
          'message': 'Unfortunately, your payment could not be completed.',
          'image': 'assets/images/paymentfailed.png',
          'color': Colors.red,
          'buttonText': 'Try Again',
        };
      case PaymentState.cancelled:
        return {
          'title': 'Payment Cancelled',
          'message': 'Your payment was cancelled. No money was deducted.',
          'image': 'assets/images/paymentfailed.png',
          'color': Colors.blueGrey,
          'buttonText': 'Retry Payment',
        };
      case PaymentState.payOnCheckIn:
        return {
          'title': 'Pay on Check-in',
          'message':
              'Your room has been reserved. You can pay when you arrive.',
          'image': 'assets/images/payoncheckin.png',
          'color': Colors.teal,
          'buttonText': 'Go to Home',
        };
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE / ILLUSTRATION
  // ---------------------------------------------------------------------------
  Widget _buildIllustration(String asset) {
    return SizedBox(
      width: double.infinity,
      height: 250,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image, size: 100, color: Colors.grey),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DETAILS CARD (Payment ID, Reason, Booking Info)
  // ---------------------------------------------------------------------------
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (razorpayData != null) ...[
            const Text("Payment Details",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _infoRow("Payment ID", razorpayData?['paymentId']),
            _infoRow("Order ID", razorpayData?['orderId']),
            _infoRow("Signature", razorpayData?['signature']),
            const SizedBox(height: 16),
          ],
          if (booking != null) ...[
            const Text("Booking Details",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _infoRow("Booking ID", booking?['bookingId']),
            _infoRow("Hotel ID", booking?['booking']?['hotelId']),
            _infoRow("Check-in", booking?['booking']?['dates']?['checkIn']),
            _infoRow("Check-out", booking?['booking']?['dates']?['checkOut']),
            _infoRow(
                "Total Amount", booking?['pricing']?['totalAmount'].toString()),
            const SizedBox(height: 16),
          ],
          if (reason != null) ...[
            const Text("Reason", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(reason!,
                style: TextStyle(color: Colors.red.shade700, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUTTON AT BOTTOM
  // ---------------------------------------------------------------------------
  Widget _buildActionButton(BuildContext context, String text) {
    return ElevatedButton(
      onPressed: () {
        if (state == PaymentState.processing) {
          // Maybe trigger a backend refresh
        }
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
