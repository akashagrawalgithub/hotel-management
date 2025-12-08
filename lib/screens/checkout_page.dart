import 'package:flash_room/constants/app_constants.dart';
import 'package:flash_room/network/dio_client_impl.dart';
import 'package:flash_room/screens/payment_status_page.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/payment_states.dart';
import '../l10n/app_localizations.dart';
import '../services/booking_payment_service.dart';
import 'notification_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int adultCount;
  final int childCount;
  final String? selectedCoupon;
  final double? totalPrice;

  const CheckoutPage({
    super.key,
    required this.hotel,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.adultCount,
    required this.childCount,
    this.selectedCoupon,
    this.totalPrice,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedCoupon;
  final service = BookingPaymentService(
    client: DioClientImpl(), // or DioClientImpl()
    baseUrl: AppConstants.baseUrl,
  );

  @override
  void initState() {
    super.initState();
    _selectedCoupon = widget.selectedCoupon;
  }

  int get _nights {
    return widget.checkOutDate.difference(widget.checkInDate).inDays;
  }

  double get _basePricePerNight {
    final selectedRoom = widget.hotel['selectedRoom'] as Map<String, dynamic>?;
    if (selectedRoom != null) {
      final basePrice = _getPriceValue(selectedRoom['basePrice'] ?? 0);
      if (basePrice > 0) {
        return basePrice;
      }
    }

    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    return _getPriceValue(widget.hotel['price'] ?? hotelData['price'] ?? 0);
  }

  double get _taxRate {
    final selectedRoom = widget.hotel['selectedRoom'] as Map<String, dynamic>?;
    if (selectedRoom != null) {
      final taxRate = _getPriceValue(selectedRoom['taxRate'] ?? 0);
      if (taxRate > 0) {
        return taxRate;
      }
    }
    return 0.0;
  }

  double get _totalPrice {
    // Use passed totalPrice if available, otherwise calculate
    if (widget.totalPrice != null && widget.totalPrice! > 0) {
      return widget.totalPrice!;
    }

    final basePrice = _basePricePerNight * _nights;
    final taxRate = _taxRate;
    if (basePrice > 0 && taxRate > 0) {
      final taxAmount = (basePrice * taxRate / 100);
      return basePrice + taxAmount;
    }
    return basePrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyCard(),
            const SizedBox(height: 20),
            _buildBookingSection(),
            const SizedBox(height: 20),
            _buildPriceDetails(),
            const SizedBox(height: 20),
            /* removed as requested by client */
            // _buildPromoSection(context),
            // const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.red,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: const Text(
        'Checkout',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon:
                const Icon(Icons.notifications, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard() {
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final hotelName = widget.hotel['name'] ?? hotelData['name'] ?? '';
    final location =
        widget.hotel['location'] ?? _getLocationString(hotelData) ?? '';

    // Get rating
    double rating = 0.0;
    final hotelRating = widget.hotel['rating'] ?? hotelData['rating'];
    if (hotelRating is num) {
      rating = hotelRating.toDouble();
    } else if (hotelRating is Map) {
      rating = (hotelRating['average'] ?? 0.0).toDouble();
    }

    // Get review count
    int reviewCount = 0;
    if (hotelRating is Map && hotelRating['totalReviews'] != null) {
      reviewCount = (hotelRating['totalReviews'] as num).toInt();
    } else {
      final reviews = hotelData['reviews'] ?? [];
      if (reviews is List) {
        reviewCount = reviews.length;
      }
    }

    // Get image
    String? imageUrl;
    final imageData = widget.hotel['image'] ?? hotelData['images']?[0];
    if (imageData != null) {
      if (imageData is String) {
        imageUrl = imageData;
      } else if (imageData is Map && imageData['url'] != null) {
        imageUrl = imageData['url'].toString();
      }
    }

    // Get price
    final selectedRoom = widget.hotel['selectedRoom'] as Map<String, dynamic>?;
    double pricePerNight = 0.0;
    if (selectedRoom != null) {
      final basePrice = _getPriceValue(selectedRoom['basePrice'] ?? 0);
      final taxRate = _getPriceValue(selectedRoom['taxRate'] ?? 0);
      pricePerNight = basePrice + (basePrice * taxRate / 100);
    } else {
      pricePerNight =
          _getPriceValue(widget.hotel['price'] ?? hotelData['price'] ?? 0);
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _getImageWidget(imageUrl, width: 100, height: 100),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotelName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '₹ ${_formatPrice(pricePerNight)} /night',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star,
                      color: AppColors.gradientStart, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$reviewCount reviews',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _getLocationString(Map<String, dynamic> hotelData) {
    final location = hotelData['location'];
    if (location == null) return null;

    if (location is Map) {
      final city = location['city'] ?? '';
      final state = location['state'] ?? '';
      final address = location['address'] ?? '';

      if (city.isNotEmpty && state.isNotEmpty) {
        return '$city, $state';
      } else if (city.isNotEmpty) {
        return city;
      } else if (state.isNotEmpty) {
        return state;
      } else if (address.isNotEmpty) {
        return address;
      }
    }
    return null;
  }

  Widget _getImageWidget(String? imageUrl,
      {required double width, required double height}) {
    String imagePath = 'assets/images/booking.jpg';

    if (imageUrl != null && imageUrl.isNotEmpty) {
      imagePath = imageUrl;
    }

    final isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/booking.jpg',
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/booking.jpg',
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        },
      );
    }
  }

  double _getPriceValue(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[₹Rs,\s]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  String _formatPrice(double price) {
    if (price == 0) return '0';
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildBookingSection() {
    final selectedRoom = widget.hotel['selectedRoom'] as Map<String, dynamic>?;
    final roomType = selectedRoom?['type'] ?? '';

    // Get guest details from passed data
    final guestDetails = widget.hotel['guestDetails'] as Map<String, dynamic>?;
    final phone = guestDetails?['phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Booking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 15),
          _buildBookingItem(
            Icons.calendar_today,
            'Dates',
            '${widget.checkInDate.day} - ${widget.checkOutDate.day} ${_getMonthName(widget.checkOutDate.month)} ${widget.checkOutDate.year}',
          ),
          const SizedBox(height: 15),
          _buildBookingItem(
            Icons.person,
            'Guest',
            '${widget.guestCount} Guests (1 Room)',
          ),
          if (selectedRoom != null && roomType.isNotEmpty) ...[
            const SizedBox(height: 15),
            _buildBookingItem(
              Icons.bed,
              'Room type',
              roomType,
            ),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 15),
            _buildBookingItem(
              Icons.phone,
              'Phone',
              phone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 15),
          if (_basePricePerNight > 0) ...[
            _buildPriceItem(
                'Base Price : $_nights ${AppLocalizations.of(context)?.nightWord ?? 'Night'}',
                '₹ ${(_basePricePerNight * _nights).toStringAsFixed(0)}'),
            if (_taxRate > 0) ...[
              const SizedBox(height: 10),
              _buildPriceItem('Tax Rate (${_taxRate.toStringAsFixed(0)}%)',
                  '₹ ${((_basePricePerNight * _nights) * _taxRate / 100).toStringAsFixed(0)}'),
            ],
          ] else ...[
            _buildPriceItem(
                'Total : $_nights ${AppLocalizations.of(context)?.nightWord ?? 'Night'}',
                '₹ ${_formatPrice(_totalPrice)}'),
          ],
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total price',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '₹ ${_totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPromoSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showPromoCodeSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.gradientStart.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.percent, color: AppColors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedCoupon ??
                          (AppLocalizations.of(context)?.select ?? 'Select'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedCoupon != null
                            ? Colors.black
                            : AppColors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoCodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PromoCodeBottomSheet(
        selectedCoupon: _selectedCoupon,
        onCouponSelected: (coupon) {
          setState(() {
            _selectedCoupon = coupon;
          });
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total price',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹ ${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                handleBookingAndPayment(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Check Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODO : use real data
  Future<void> handleBookingAndPayment(BuildContext context) async {
    try {
      final guestDetails =
          widget.hotel['guestDetails'] as Map<String, dynamic>?;

      final result = await service.startBookingPayment(
        bookingBody: {
          "hotelId": widget.hotel['id'],
          "roomId": widget.hotel['selectedRoom']?['_id'],
          "checkIn": widget.checkInDate.toString(),
          "checkOut": widget.checkOutDate.toString(),
          "adults": widget.adultCount,
          "children": widget.childCount,
          "guestDetails": guestDetails,
          "roomsRequested": 1,
        },
        context: context,
      );
      print('hotel data ${result}\n');
      final status = result["status"];

      // If cancelled → only toast, no navigation
      if (status == "cancelled") {
        final reason = result["error"] ?? "Payment cancelled by user";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason)),
        );

        return; // stop here
      }

      // SUCCESS → navigate to PaymentStatusPage

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentStatusPage(
            state: PaymentState.success,
            booking: result["booking"],
            razorpayData: result["razorpay"],
          ),
        ),
      );
    } catch (e) {
      // Unexpected crash
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Something went wrong: $e")));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentStatusPage(
            state: PaymentState.failed,
            reason: e.toString(),
          ),
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class DatePickerBottomSheet extends StatefulWidget {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final Function(DateTime, DateTime) onDatesSelected;

  const DatePickerBottomSheet({
    super.key,
    required this.checkInDate,
    required this.checkOutDate,
    required this.onDatesSelected,
  });

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime _currentMonth = DateTime.now();

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.checkInDate;
    _selectedEndDate = widget.checkOutDate;
    if (_currentMonth.month !=
        (_selectedStartDate?.month ?? DateTime.now().month)) {
      _currentMonth = DateTime(_selectedStartDate?.year ?? DateTime.now().year,
          _selectedStartDate?.month ?? DateTime.now().month);
    }
  }

  bool _isDateBeforeToday(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isBefore(_today);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF9E0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left, size: 20),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month - 1);
                        });
                      },
                    ),
                    Text(
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right, size: 20),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildCalendar(),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.red, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _selectedStartDate != null && _selectedEndDate != null
                            ? () {
                                widget.onDatesSelected(
                                    _selectedStartDate!, _selectedEndDate!);
                                Navigator.pop(context);
                              }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: firstDayOfWeek +
                  daysInMonth +
                  (42 - firstDayOfWeek - daysInMonth),
              itemBuilder: (context, index) {
                DateTime date;
                bool isCurrentMonth;

                if (index < firstDayOfWeek) {
                  final prevMonth =
                      DateTime(_currentMonth.year, _currentMonth.month - 1, 0);
                  final day = prevMonth.day - firstDayOfWeek + index + 1;
                  date = DateTime(
                      _currentMonth.year, _currentMonth.month - 1, day);
                  isCurrentMonth = false;
                } else if (index < firstDayOfWeek + daysInMonth) {
                  final day = index - firstDayOfWeek + 1;
                  date = DateTime(_currentMonth.year, _currentMonth.month, day);
                  isCurrentMonth = true;
                } else {
                  final day = index - firstDayOfWeek - daysInMonth + 1;
                  date = DateTime(
                      _currentMonth.year, _currentMonth.month + 1, day);
                  isCurrentMonth = false;
                }

                return _buildDateCell(date, isCurrentMonth: isCurrentMonth);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCell(DateTime date, {required bool isCurrentMonth}) {
    final isStartDate = _selectedStartDate != null &&
        date.year == _selectedStartDate!.year &&
        date.month == _selectedStartDate!.month &&
        date.day == _selectedStartDate!.day;
    final isEndDate = _selectedEndDate != null &&
        date.year == _selectedEndDate!.year &&
        date.month == _selectedEndDate!.month &&
        date.day == _selectedEndDate!.day;
    final isInRange = _selectedStartDate != null &&
        _selectedEndDate != null &&
        date.isAfter(_selectedStartDate!) &&
        date.isBefore(_selectedEndDate!);

    final isPastDate = _isDateBeforeToday(date);
    final isSelectable = isCurrentMonth && !isPastDate;

    return GestureDetector(
      onTap: isSelectable
          ? () {
              if (_selectedStartDate == null ||
                  (_selectedStartDate != null && _selectedEndDate != null)) {
                if (!isPastDate) {
                  setState(() {
                    _selectedStartDate = date;
                    _selectedEndDate = null;
                  });
                }
              } else if (_selectedStartDate != null &&
                  _selectedEndDate == null) {
                if (date.isBefore(_selectedStartDate!)) {
                  if (!isPastDate) {
                    setState(() {
                      _selectedEndDate = _selectedStartDate;
                      _selectedStartDate = date;
                    });
                  }
                } else {
                  setState(() {
                    _selectedEndDate = date;
                  });
                }
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isStartDate || isEndDate
              ? AppColors.red
              : isInRange
                  ? AppColors.red.withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isStartDate || isEndDate
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isStartDate || isEndDate
                  ? Colors.white
                  : isInRange
                      ? Colors.black
                      : isPastDate
                          ? Colors.grey.shade300
                          : isCurrentMonth
                              ? Colors.black
                              : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class PromoCodeBottomSheet extends StatefulWidget {
  final String? selectedCoupon;
  final Function(String?) onCouponSelected;

  const PromoCodeBottomSheet({
    super.key,
    required this.selectedCoupon,
    required this.onCouponSelected,
  });

  @override
  State<PromoCodeBottomSheet> createState() => _PromoCodeBottomSheetState();
}

class _PromoCodeBottomSheetState extends State<PromoCodeBottomSheet> {
  late String? _selectedCoupon;

  final List<Map<String, dynamic>> _coupons = const [
    {
      'title': '50% Cashback',
      'expiry': 'Expired in 2 days',
      'code': 'CASHBACK50',
    },
    {
      'title': '15% Discount',
      'expiry': 'Expired in 1 days',
      'code': 'DISCOUNT15',
    },
    {
      'title': '10% Cashback',
      'expiry': 'Expired in 7 days',
      'code': 'CASHBACK10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCoupon = widget.selectedCoupon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Coupon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                final isSelected = _selectedCoupon == coupon['code'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCoupon =
                          isSelected ? null : coupon['code'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.red : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.percent,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coupon['title'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? AppColors.red : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    coupon['expiry'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'See Detail',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.red,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.red, size: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onCouponSelected(_selectedCoupon);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Use Coupon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
