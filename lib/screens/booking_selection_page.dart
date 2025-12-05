import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../l10n/app_localizations.dart';
import 'checkout_page.dart';

class BookingSelectionPage extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const BookingSelectionPage({
    super.key,
    required this.hotel,
  });

  @override
  State<BookingSelectionPage> createState() => _BookingSelectionPageState();
}

class _BookingSelectionPageState extends State<BookingSelectionPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;
  int _adultGuestCount = 1;
  int _childGuestCount = 0;
  String? _selectedCoupon;

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime(2025, 11, 12);
    _checkOutDate = DateTime(2025, 11, 14);
  }

  int get _nights {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double get _pricePerNight {
    return double.tryParse(widget.hotel['price']?.toString() ?? '480') ?? 480.0;
  }

  double get _totalPrice {
    double basePrice = _pricePerNight * _nights;
    double cleaningFee = 15.0;
    double serviceFee = 40.0;
    double discount = _selectedCoupon != null ? 100.0 : 0.0;
    return basePrice + cleaningFee + serviceFee - discount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyCard(),
            const SizedBox(height: 20),
            _buildDateSection(),
            const SizedBox(height: 20),
            _buildGuestSection(),
            const SizedBox(height: 20),
            _buildPaymentMethodSection(),
            const SizedBox(height: 20),
            _buildPaymentDetails(),
            const SizedBox(height: 20),
            _buildGuestInformation(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
      title: Text(
        AppLocalizations.of(context)?.booking ?? 'Booking',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildPropertyCard() {
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
            child: Image.asset(
              widget.hotel['image'] ?? 'assets/images/booking.jpg',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotel['name'] ?? 'Amirtha Homestay',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.hotel['location'] ?? 'Sriangam,tamil nadu',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star,
                        color: AppColors.gradientStart, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      widget.hotel['rating']?.toString() ?? '4.5',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '549 ${AppLocalizations.of(context)?.reviews ?? 'reviews'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.date ?? 'Date',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showDatePicker(),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.red, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.checkIn ?? 'Check - In',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _checkInDate != null
                              ? '${_getMonthName(_checkInDate!.month)} ${_checkInDate!.day}, ${_checkInDate!.year}'
                              : AppLocalizations.of(context)?.selectDate ??
                                  'Select',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: InkWell(
                  onTap: () => _showDatePicker(),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.red, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.checkOut ??
                              'Check - Out',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _checkOutDate != null
                              ? '${_getMonthName(_checkOutDate!.month)} ${_checkOutDate!.day}, ${_checkOutDate!.year}'
                              : AppLocalizations.of(context)?.selectDate ??
                                  'Select',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSection() {
    // Always calculate total
    _guestCount = _adultGuestCount + _childGuestCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.guest ?? 'Guest',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          // Total Guests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Guests',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                '$_guestCount',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---------------- ADULT COUNT ----------------
          _buildCounterRow(
            label: "Adults",
            value: _adultGuestCount,
            onAdd: () {
              setState(() {
                _adultGuestCount++;
              });
            },
            onRemove: () {
              if (_adultGuestCount > 1) {
                setState(() {
                  _adultGuestCount--;
                });
              }
            },
          ),

          const SizedBox(height: 15),

          // ---------------- CHILD COUNT ----------------
          _buildCounterRow(
            label: "Children",
            value: _childGuestCount,
            onAdd: () {
              setState(() {
                _childGuestCount++;
              });
            },
            onRemove: () {
              if (_childGuestCount > 0) {
                setState(() {
                  _childGuestCount--;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        Row(
          children: [
            // Remove button
            IconButton(
              icon: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove, color: AppColors.red, size: 18),
              ),
              onPressed: onRemove,
            ),

            // Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$value',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // Add button
            IconButton(
              icon: Container(
                width: 35,
                height: 35,
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildGuestSection() {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           AppLocalizations.of(context)?.guest ?? 'Guest',
  //           style: const TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black,
  //           ),
  //         ),
  //         const SizedBox(height: 15),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               AppLocalizations.of(context)?.numberOfGuests ??
  //                   'Number of Guests',
  //               style: const TextStyle(
  //                 fontSize: 14,
  //                 color: Colors.black,
  //               ),
  //             ),
  //             Row(
  //               children: [
  //                 IconButton(
  //                   icon: Container(
  //                     width: 35,
  //                     height: 35,
  //                     decoration: BoxDecoration(
  //                       color: AppColors.red.withOpacity(0.2),
  //                       shape: BoxShape.circle,
  //                     ),
  //                     child: const Icon(Icons.remove,
  //                         color: AppColors.red, size: 18),
  //                   ),
  //                   onPressed: _guestCount > 1
  //                       ? () {
  //                           setState(() {
  //                             _guestCount--;
  //                           });
  //                         }
  //                       : null,
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 20),
  //                   child: Text(
  //                     '$_guestCount',
  //                     style: const TextStyle(
  //                         fontSize: 18, fontWeight: FontWeight.bold),
  //                   ),
  //                 ),
  //                 IconButton(
  //                   icon: Container(
  //                     width: 35,
  //                     height: 35,
  //                     decoration: BoxDecoration(
  //                       color: AppColors.red,
  //                       shape: BoxShape.circle,
  //                     ),
  //                     child:
  //                         const Icon(Icons.add, color: Colors.white, size: 18),
  //                   ),
  //                   onPressed: () {
  //                     setState(() {
  //                       _guestCount++;
  //                     });
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pay With',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.grey, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Razorpay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '*******6587',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: AppColors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
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
          Text(
            AppLocalizations.of(context)?.paymentDetails ?? 'Payment Details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          _buildPriceItem(
              '${AppLocalizations.of(context)?.total ?? 'Total'} : $_nights ${AppLocalizations.of(context)?.nightWord ?? 'Night'}',
              'Rs ${(_pricePerNight * _nights).toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          _buildPriceItem(
              AppLocalizations.of(context)?.cleaningFee ?? 'Cleaning Fee',
              'Rs 15'),
          const SizedBox(height: 10),
          _buildPriceItem(
              AppLocalizations.of(context)?.serviceFee ?? 'Service Fee',
              'Rs 40'),
          const SizedBox(height: 10),
          _buildPriceItem(AppLocalizations.of(context)?.discount ?? 'Discount',
              'Rs ${_selectedCoupon != null ? '100' : '0'}'),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.totalPayment ?? 'Total Payment:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Rs ${_totalPrice.toStringAsFixed(0)}',
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

  Widget _buildGuestInformation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.guestInformation ??
                    'Guest Information',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInputField(
              AppLocalizations.of(context)?.fullName ?? 'Full Name'),
          const SizedBox(height: 15),
          _buildInputField(AppLocalizations.of(context)?.email ?? 'Email'),
          const SizedBox(height: 15),
          _buildInputField(
              AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number'),
        ],
      ),
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

  Widget _buildBottomBar() {
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
                  AppLocalizations.of(context)?.totalPrice ?? 'Total price',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs ${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _checkInDate != null && _checkOutDate != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                            hotel: widget.hotel,
                            checkInDate: _checkInDate!,
                            checkOutDate: _checkOutDate!,
                            guestCount: _guestCount,
                            selectedCoupon: _selectedCoupon,
                          ),
                        ),
                      );
                    }
                  : null,
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
              child: Text(
                AppLocalizations.of(context)?.checkOut ?? 'Check Out',
                style: const TextStyle(
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

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DatePickerBottomSheet(
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        onDatesSelected: (checkIn, checkOut) {
          setState(() {
            _checkInDate = checkIn;
            _checkOutDate = checkOut;
          });
        },
      ),
    );
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
