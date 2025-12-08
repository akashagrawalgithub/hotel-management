import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../l10n/app_localizations.dart';
import '../services/hotel_service.dart';
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
  
  // Guest Details Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idProofController = TextEditingController();
  String _specialRequests = 'none';
  
  // Address Controllers
  final TextEditingController _addressLineController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  
  // Room data
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoadingRooms = false;
  
  // Validation errors
  String? _firstNameError;
  String? _emailError;
  String? _phoneError;
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idProofController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Get values from searchParams if available
    final searchParams = widget.hotel['searchParams'] as Map<String, dynamic>?;
    if (searchParams != null) {
      _checkInDate = searchParams['checkInDate'] as DateTime?;
      _checkOutDate = searchParams['checkOutDate'] as DateTime?;
      _adultGuestCount = searchParams['adults'] as int? ?? 1;
      _childGuestCount = searchParams['children'] as int? ?? 0;
      _guestCount = _adultGuestCount + _childGuestCount;
    } else {
      // Default values if no search params
      _checkInDate = DateTime.now().add(const Duration(days: 1));
      _checkOutDate = DateTime.now().add(const Duration(days: 3));
      _adultGuestCount = 1;
      _childGuestCount = 0;
      _guestCount = 1;
    }
    _loadHotelRooms();
  }

  Future<void> _loadHotelRooms() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRooms = true;
    });

    try {
      final hotelId = widget.hotel['id'] ?? 
                      widget.hotel['_id'] ?? 
                      widget.hotel['hotelData']?['_id'];
      if (hotelId != null && hotelId.toString().isNotEmpty) {
        final response = await HotelService.getHotelRooms(hotelId.toString());
        if (!mounted) return;
        if (response.data != null && response.data['success'] == true) {
          final rooms = response.data['rooms'] as List? ?? [];
          if (!mounted) return;
          setState(() {
            _rooms = rooms.map((room) => Map<String, dynamic>.from(room)).toList();
            _isLoadingRooms = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _isLoadingRooms = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRooms = false;
      });
    }
  }

  int get _nights {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double _getPriceValue(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[Rs,\s]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  double get _basePricePerNight {
    // Priority 1: Use selected room if available
    final selectedRoom = widget.hotel['selectedRoom'] as Map<String, dynamic>?;
    if (selectedRoom != null) {
      final basePrice = _getPriceValue(selectedRoom['basePrice'] ?? 0);
      if (basePrice > 0) {
        return basePrice;
      }
    }
    
    // Priority 2: Try to get from loaded room data
    if (_rooms.isNotEmpty) {
      final firstRoom = _rooms[0];
      final basePrice = _getPriceValue(firstRoom['basePrice'] ?? 0);
      if (basePrice > 0) {
        return basePrice;
      }
    }
    
    // Priority 3: Try to get from hotelData rooms
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final rooms = hotelData['rooms'] ?? [];
    
    if (rooms is List && rooms.isNotEmpty) {
      final firstRoom = rooms[0];
      final basePrice = _getPriceValue(firstRoom['basePrice'] ?? 0);
      if (basePrice > 0) {
        return basePrice;
      }
    }
    
    // Fallback to hotel price
    return _getPriceValue(widget.hotel['price'] ?? hotelData['price'] ?? 0);
  }

  double get _taxRate {
    // Priority 1: Use selected room if available
    final selectedRoom = widget.hotel['selectedRoom'] as Map<String, dynamic>?;
    if (selectedRoom != null) {
      final taxRate = _getPriceValue(selectedRoom['taxRate'] ?? 0);
      if (taxRate > 0) {
        return taxRate;
      }
    }
    
    // Priority 2: Try to get from loaded room data
    if (_rooms.isNotEmpty) {
      final firstRoom = _rooms[0];
      return _getPriceValue(firstRoom['taxRate'] ?? 0);
    }
    
    // Priority 3: Try to get from hotelData rooms
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final rooms = hotelData['rooms'] ?? [];
    
    if (rooms is List && rooms.isNotEmpty) {
      final firstRoom = rooms[0];
      return _getPriceValue(firstRoom['taxRate'] ?? 0);
    }
    
    return 0.0;
  }

  double get _pricePerNight {
    final basePrice = _basePricePerNight;
    final taxRate = _taxRate;
    if (basePrice > 0 && taxRate > 0) {
      return basePrice + (basePrice * taxRate / 100);
    }
    return basePrice;
  }

  double get _totalPrice {
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
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyCard(),
            if (widget.hotel['selectedRoom'] != null) ...[
              const SizedBox(height: 20),
              _buildSelectedRoomCard(),
            ],
            const SizedBox(height: 20),
            _buildDateSection(),
            const SizedBox(height: 20),
            _buildGuestSection(),
            const SizedBox(height: 20),
            // _buildPaymentMethodSection(),
            // const SizedBox(height: 20),
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
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final hotelName = widget.hotel['name'] ?? hotelData['name'] ?? '';
    final location = widget.hotel['location'] ?? _getLocationString(hotelData) ?? '';
    
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
                    if (reviewCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                        '$reviewCount ${AppLocalizations.of(context)?.reviews ?? 'reviews'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    ],
                  ],
                ),
              ],
            ),
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

  Widget _getImageWidget(String? imageUrl, {required double width, required double height}) {
    String imagePath = 'assets/images/booking.jpg';
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imagePath = imageUrl;
    }
    
    final isNetworkImage = imagePath.startsWith('http://') || imagePath.startsWith('https://');
    
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

  Widget _buildSelectedRoomCard() {
    final selectedRoom = widget.hotel['selectedRoom'] as Map<String, dynamic>?;
    if (selectedRoom == null) return const SizedBox.shrink();

    final roomType = selectedRoom['type'] ?? 'Standard Room';
    final basePrice = _getPriceValue(selectedRoom['basePrice'] ?? 0);
    final taxRate = _getPriceValue(selectedRoom['taxRate'] ?? 0);
    final finalPrice = basePrice + (basePrice * taxRate / 100);
    final capacity = selectedRoom['capacity'] ?? {};
    final roomAdults = capacity['adults'] ?? 0;
    final roomChildren = capacity['children'] ?? 0;
    final description = selectedRoom['description'] ?? '';
    final amenities = selectedRoom['amenities'] ?? [];
    final images = selectedRoom['images'] ?? [];
    String? imageUrl;
    if (images.isNotEmpty) {
      final firstImage = images[0];
      if (firstImage is String) {
        imageUrl = firstImage;
      } else if (firstImage is Map && firstImage['url'] != null) {
        imageUrl = firstImage['url'].toString();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.red.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hotel,
                color: AppColors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
          const Text(
                'Selected Room',
            style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _getImageWidget(imageUrl, width: 100, height: 100),
                ),
              if (imageUrl != null) const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '$roomAdults Adults',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (roomChildren > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.child_care, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '$roomChildren Children',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹ ${_formatPrice(finalPrice)}/night',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == 0) return '0';
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
                              : AppLocalizations.of(context)?.select ?? 'Select',
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
                          AppLocalizations.of(context)?.payNow ?? 'Pay Now',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _checkOutDate != null
                              ? '${_getMonthName(_checkOutDate!.month)} ${_checkOutDate!.day}, ${_checkOutDate!.year}'
                              : AppLocalizations.of(context)?.select ?? 'Select',
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
                AppLocalizations.of(context)?.totalGuests ?? 'Total Guests',
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
          if (_basePricePerNight > 0) ...[
            _buildPriceItem(
                'Base Price : $_nights ${AppLocalizations.of(context)?.nightWord ?? 'Night'}',
                '₹ ${(_basePricePerNight * _nights).toStringAsFixed(0)}'),
            if (_taxRate > 0) ...[
          const SizedBox(height: 10),
              _buildPriceItem(
                  'Tax Rate (${_taxRate.toStringAsFixed(0)}%)',
                  '₹ ${((_basePricePerNight * _nights) * _taxRate / 100).toStringAsFixed(0)}'),
            ],
          ] else ...[
            _buildPriceItem(
                '${AppLocalizations.of(context)?.total ?? 'Total'} : $_nights ${AppLocalizations.of(context)?.nightWord ?? 'Night'}',
                '₹ ${(_pricePerNight * _nights).toStringAsFixed(0)}'),
          ],
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

  Widget _buildGuestInformation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guest Details Section
          Text(
            'Guest Details',
            style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 20),
          // First Name
          _buildInputField(
            controller: _firstNameController,
            hint: 'First Name*',
            isRequired: true,
            errorText: _firstNameError,
          ),
          const SizedBox(height: 15),
          // Last Name
          _buildInputField(
            controller: _lastNameController,
            hint: 'Last Name',
          ),
          const SizedBox(height: 15),
          // Email
          _buildInputField(
            controller: _emailController,
            hint: 'Email*',
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            errorText: _emailError,
          ),
          const SizedBox(height: 15),
          // Phone
          _buildInputField(
            controller: _phoneController,
            hint: 'Phone*',
            keyboardType: TextInputType.phone,
            isRequired: true,
            errorText: _phoneError,
          ),
          const SizedBox(height: 15),
          // ID Proof
          _buildInputField(
            controller: _idProofController,
            hint: 'ID Proof',
          ),
          const SizedBox(height: 15),
          // Special Requests
          _buildDropdownField(),
          const SizedBox(height: 30),
          // Complete Registration Payment Section
          Text(
            'Complete Registration Payment',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 20),
          // Address Line
          _buildInputField(
            controller: _addressLineController,
            hint: 'Address Line',
          ),
          const SizedBox(height: 15),
          // City
          _buildInputField(
            controller: _cityController,
            hint: 'City',
          ),
          const SizedBox(height: 15),
          // State
          _buildInputField(
            controller: _stateController,
            hint: 'State',
          ),
          const SizedBox(height: 15),
          // Postal Code
          _buildInputField(
            controller: _postalCodeController,
            hint: 'Postal Code',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.red : Colors.grey.shade300,
              width: hasError ? 2 : 1,
            ),
      ),
      child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (value) {
              if (hasError) {
                setState(() {
                  if (hint.contains('First Name')) {
                    _firstNameError = null;
                  } else if (hint.contains('Email')) {
                    _emailError = null;
                  } else if (hint.contains('Phone')) {
                    _phoneError = null;
                  }
                });
              }
            },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
        ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              errorText,
              style: TextStyle(
                color: AppColors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _specialRequests,
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          {'key': 'none', 'label': AppLocalizations.of(context)?.none ?? 'None'},
          {'key': 'earlyCheckIn', 'label': AppLocalizations.of(context)?.earlyCheckIn ?? 'Early Check-in'},
          {'key': 'lateCheckOut', 'label': AppLocalizations.of(context)?.lateCheckOut ?? 'Late Check-out'},
          {'key': 'extraBed', 'label': AppLocalizations.of(context)?.extraBed ?? 'Extra Bed'},
          {'key': 'babyCrib', 'label': AppLocalizations.of(context)?.babyCrib ?? 'Baby Crib'},
          {'key': 'wheelchairAccess', 'label': AppLocalizations.of(context)?.wheelchairAccess ?? 'Wheelchair Access'},
        ].map((item) {
          return DropdownMenuItem<String>(
            value: item['key'] as String,
            child: Text(
              item['label'] as String,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _specialRequests = newValue;
            });
          }
        },
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
              onPressed: _checkInDate != null && _checkOutDate != null
                  ? () {
                      if (_validateForm()) {
                        // Room selection should already be done in hotel detail page
                        // Just proceed to checkout with all data
                        final hotelForCheckout = Map<String, dynamic>.from(widget.hotel);
                        hotelForCheckout['searchParams'] = {
                          'checkInDate': _checkInDate,
                          'checkOutDate': _checkOutDate,
                          'adults': _adultGuestCount,
                          'children': _childGuestCount,
                        };
                        // Add guest details
                        hotelForCheckout['guestDetails'] = {
                          'firstName': _firstNameController.text.trim(),
                          'lastName': _lastNameController.text.trim(),
                          'email': _emailController.text.trim(),
                          'phone': _phoneController.text.trim(),
                          'idProof': _idProofController.text.trim(),
                          'specialRequests': _specialRequests,
                          'address': {
                            'street': _addressLineController.text.trim(),
                            'city': _cityController.text.trim(),
                            'state': _stateController.text.trim(),
                            'postalCode': _postalCodeController.text.trim(),
                          },
                        };
                        
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                              hotel: hotelForCheckout,
                            checkInDate: _checkInDate!,
                            checkOutDate: _checkOutDate!,
                            guestCount: _guestCount,
                            selectedCoupon: _selectedCoupon,
                            totalPrice: _totalPrice,
                          ),
                        ),
                      );
                      }
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
                AppLocalizations.of(context)?.payNow ?? 'Pay Now',
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

  bool _validateForm() {
    bool isValid = true;
    
    // Clear previous errors
    setState(() {
      _firstNameError = null;
      _emailError = null;
      _phoneError = null;
    });
    
    // Validate First Name
    if (_firstNameController.text.trim().isEmpty) {
      setState(() {
        _firstNameError = AppLocalizations.of(context)?.pleaseFillThisField ?? 'Please fill this field';
        isValid = false;
      });
    }
    
    // Validate Email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = AppLocalizations.of(context)?.pleaseFillThisField ?? 'Please fill this field';
        isValid = false;
      });
    } else if (!_isValidEmail(email)) {
      setState(() {
        _emailError = AppLocalizations.of(context)?.pleaseEnterValidEmail ?? 'Please enter a valid email';
        isValid = false;
      });
    }
    
    // Validate Phone
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneError = AppLocalizations.of(context)?.pleaseFillThisField ?? 'Please fill this field';
        isValid = false;
      });
    }
    
    // Scroll to first error if validation fails
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseFillAllMandatoryFields ?? 'Please fill all mandatory fields',
          ),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
    return isValid;
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showRoomSelectionDialog(
    BuildContext context,
    List<Map<String, dynamic>> rooms,
  ) {
    Map<String, dynamic>? selectedRoom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFDF9E0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Room',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final isSelected = selectedRoom?['_id'] == room['_id'];
                      final roomType = room['type'] ?? 'Standard Room';
                      final basePrice = _getPriceValue(room['basePrice'] ?? 0);
                      final taxRate = _getPriceValue(room['taxRate'] ?? 0);
                      final finalPrice = basePrice + (basePrice * taxRate / 100);
                      final capacity = room['capacity'] ?? {};
                      final roomAdults = capacity['adults'] ?? 0;
                      final roomChildren = capacity['children'] ?? 0;
                      final description = room['description'] ?? '';
                      final images = room['images'] ?? [];
                      String? imageUrl;
                      if (images.isNotEmpty) {
                        final firstImage = images[0];
                        if (firstImage is String) {
                          imageUrl = firstImage;
                        } else if (firstImage is Map && firstImage['url'] != null) {
                          imageUrl = firstImage['url'].toString();
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedRoom = room;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.red : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  child: _getImageWidget(imageUrl, width: 120, height: 120),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              roomType,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (description.isNotEmpty) ...[
                                        Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$roomAdults Adults',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (roomChildren > 0) ...[
                                            const SizedBox(width: 12),
                                            Icon(Icons.child_care, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$roomChildren Children',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₹ ${_formatPrice(finalPrice)}/night',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.cancel ?? 'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedRoom != null
                              ? () {
                                  final hotelWithRoom = Map<String, dynamic>.from(widget.hotel);
                                  hotelWithRoom['selectedRoom'] = selectedRoom;
                                  hotelWithRoom['searchParams'] = {
                                    'checkInDate': _checkInDate,
                                    'checkOutDate': _checkOutDate,
                                    'adults': _adultGuestCount,
                                    'children': _childGuestCount,
                                  };
                                  // Add guest details
                                  hotelWithRoom['guestDetails'] = {
                                    'firstName': _firstNameController.text.trim(),
                                    'lastName': _lastNameController.text.trim(),
                                    'email': _emailController.text.trim(),
                                    'phone': _phoneController.text.trim(),
                                    'idProof': _idProofController.text.trim(),
                                    'specialRequests': _specialRequests,
                                    'address': {
                                      'street': _addressLineController.text.trim(),
                                      'city': _cityController.text.trim(),
                                      'state': _stateController.text.trim(),
                                      'postalCode': _postalCodeController.text.trim(),
                                    },
                                  };
                                  Navigator.pop(context);
                                  // Navigate to checkout
                                  // Calculate total price with selected room
                                  double calculatedTotal = 0.0;
                                  final room = selectedRoom;
                                  if (room != null) {
                                    final selectedBasePrice = _getPriceValue(room['basePrice'] ?? 0);
                                    final selectedTaxRate = _getPriceValue(room['taxRate'] ?? 0);
                                    final nights = _checkOutDate!.difference(_checkInDate!).inDays;
                                    final basePriceTotal = selectedBasePrice * nights;
                                    final taxAmount = selectedTaxRate > 0 ? (basePriceTotal * selectedTaxRate / 100) : 0;
                                    calculatedTotal = basePriceTotal + taxAmount;
                                  }
                                  
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutPage(
                                        hotel: hotelWithRoom,
                                        checkInDate: _checkInDate!,
                                        checkOutDate: _checkOutDate!,
                                        guestCount: _guestCount,
                                        selectedCoupon: _selectedCoupon,
                                        totalPrice: calculatedTotal,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.continueText ?? 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
