import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/hotel_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'notification_page.dart';
import 'hotel_detail_page.dart';

class MyBookingsPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  
  const MyBookingsPage({super.key, this.onBackPressed});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _historyBookings = [];
  bool _isLoading = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingHistory = true;
    });

    try {
      final email = await AuthService.getUserEmail();
      if (email != null && email.isNotEmpty) {
        final response = await HotelService.getBookingHistory(email);
        if (!mounted) return;

        if (response.data != null && response.data['success'] == true) {
          final bookingsData = response.data['data'] ?? [];
          final now = DateTime.now();
          
          final List<Map<String, dynamic>> allBookings = [];
          final List<Map<String, dynamic>> bookedList = [];
          final List<Map<String, dynamic>> historyList = [];

          for (var booking in bookingsData) {
            final hotel = booking['hotelId'];
            final room = booking['roomId'] ?? {};
            final dates = booking['dates'] ?? {};
            final guests = booking['guests'] ?? {};
            final pricing = booking['pricing'] ?? {};
            final guestDetails = booking['guestDetails'] ?? {};

            // Parse location
            String locationString = AppLocalizations.of(context)?.locationNotAvailable ?? 'Location not available';
            if (hotel != null && hotel is Map) {
              final location = hotel['location'] ?? {};
              if (location is Map) {
                final city = location['city'] ?? '';
                final state = location['state'] ?? '';
                final address = location['address'] ?? '';
                if (city.isNotEmpty && state.isNotEmpty) {
                  locationString = '$city, $state';
                } else if (city.isNotEmpty) {
                  locationString = city;
                } else if (state.isNotEmpty) {
                  locationString = state;
                } else if (address.isNotEmpty) {
                  locationString = address;
                }
              }
            }

            // Parse image
            String? imageUrl;
            if (hotel != null && hotel is Map) {
              final images = hotel['images'] ?? [];
              if (images.isNotEmpty) {
                final firstImage = images[0];
                if (firstImage is Map && firstImage['url'] != null) {
                  imageUrl = firstImage['url'].toString();
                } else if (firstImage is String) {
                  imageUrl = firstImage;
                }
              }
            }

            // Parse dates
            DateTime? checkIn;
            DateTime? checkOut;
            if (dates['checkIn'] != null) {
              try {
                checkIn = DateTime.parse(dates['checkIn']);
              } catch (e) {
                checkIn = null;
              }
            }
            if (dates['checkOut'] != null) {
              try {
                checkOut = DateTime.parse(dates['checkOut']);
              } catch (e) {
                checkOut = null;
              }
            }

            String datesString = AppLocalizations.of(context)?.datesNotAvailable ?? 'Dates not available';
            if (checkIn != null && checkOut != null) {
              final monthNames = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
              ];
              datesString = '${checkIn.day} ${monthNames[checkIn.month - 1]} - ${checkOut.day} ${monthNames[checkOut.month - 1]} ${checkOut.year}';
            }

            // Parse guests
            final adults = guests['adults'] ?? 0;
            final children = guests['children'] ?? 0;
            final totalGuests = adults + children;
            final localizations = AppLocalizations.of(context);
            final guestText = totalGuests > 1 
                ? (localizations?.guests ?? 'Guests')
                : (localizations?.guest ?? 'Guest');
            final guestsString = '$totalGuests $guestText (${adults} ${localizations?.adults ?? 'Adults'}${children > 0 ? ', $children ${localizations?.children ?? 'Children'}' : ''})';

            // Room type
            final roomType = room['type'] ?? 'Room';

            // Status
            final status = booking['status'] ?? 'pending';
            final paymentStatus = booking['paymentStatus'] ?? 'pending';

            // Price
            final totalAmount = pricing['totalAmount'] ?? 0;

            final bookingMap = {
              'id': booking['_id'] ?? '',
              'name': hotel != null && hotel is Map ? (hotel['name'] ?? 'Hotel Name') : 'Hotel Name',
              'location': locationString,
              'price': totalAmount.toString(),
              'dates': datesString,
              'checkIn': checkIn,
              'checkOut': checkOut,
              'guests': guestsString,
              'roomType': roomType,
              'status': status,
              'paymentStatus': paymentStatus,
              'image': imageUrl,
              'hasImage': imageUrl != null,
              'hotelData': hotel ?? {},
              'roomData': room,
              'bookingData': booking,
            };

            allBookings.add(bookingMap);

            // Separate into booked and history based on checkOut date
            if (checkOut != null) {
              if (checkOut.isAfter(now)) {
                bookedList.add(bookingMap);
              } else {
                historyList.add(bookingMap);
              }
            } else {
              // If no checkOut date, consider it as booked
              bookedList.add(bookingMap);
            }
          }

          if (!mounted) return;
          setState(() {
            _bookings = bookedList;
            _historyBookings = historyList;
            _isLoading = false;
            _isLoadingHistory = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _bookings = [];
            _historyBookings = [];
            _isLoading = false;
            _isLoadingHistory = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(),
                _buildHistoryList(),
              ],
            ),
          ),
        ],
      ),
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
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      title: Text(
        AppLocalizations.of(context)?.myBookings ?? 'My Bookings',
        style: const TextStyle(
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
            icon: const Icon(Icons.notifications, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.findYourSpace ?? 'Find your space',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? AppColors.red.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${AppLocalizations.of(context)?.booked ?? 'Booked'} (${_bookings.length})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 0 ? Colors.black : AppColors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? AppColors.red.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${AppLocalizations.of(context)?.history ?? 'History'} (${_historyBookings.length})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 1 ? Colors.black : AppColors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
        ),
      );
    }
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.noBookingsFound ?? 'No bookings found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(_bookings[index]);
      },
    );
  }

  Widget _buildHistoryList() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
        ),
      );
    }
    if (_historyBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.noBookingHistoryFound ?? 'No booking history found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _historyBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(_historyBookings[index]);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final hotelData = booking['hotelData'] ?? {};
    final hasImage = booking['hasImage'] == true;
    final imageUrl = booking['image'];
    final status = booking['status'] ?? 'pending';
    final paymentStatus = booking['paymentStatus'] ?? 'pending';

    return GestureDetector(
      onTap: () {
        if (hotelData.isNotEmpty) {
          final hotelForDetail = {
            'id': hotelData['_id'] ?? booking['id'] ?? '',
            'name': hotelData['name'] ?? booking['name'] ?? 'Hotel Name',
            'location': booking['location'] ?? 'Location not available',
            'price': booking['price'] ?? '0',
            'rating': hotelData['rating']?['average'] ?? 0.0,
            'image': imageUrl ?? 'assets/images/booking.jpg',
            'description': hotelData['description'] ?? '',
            'amenities': hotelData['amenities'] ?? [],
            'hotelData': hotelData,
          };
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HotelDetailPage(hotel: hotelForDetail),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: hasImage
            ? _buildCardWithImage(booking, hotelData, status, paymentStatus)
            : _buildCardWithoutImage(booking, hotelData, status, paymentStatus),
      ),
    );
  }

  Widget _buildCardWithImage(Map<String, dynamic> booking, Map<String, dynamic> hotelData, String status, String paymentStatus) {
    final imageUrl = booking['image'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
          child: imageUrl != null && imageUrl.toString().startsWith('http')
              ? Image.network(
                  imageUrl.toString(),
                  width: 120,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder(120, 180);
                  },
                )
              : _buildImagePlaceholder(120, 180),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildCardContent(booking, hotelData, status, paymentStatus),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWithoutImage(Map<String, dynamic> booking, Map<String, dynamic> hotelData, String status, String paymentStatus) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _buildCardContent(booking, hotelData, status, paymentStatus),
    );
  }

  Widget _buildImagePlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.hotel,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> booking, Map<String, dynamic> hotelData, String status, String paymentStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['name'] ?? 'Hotel Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey.shade600, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking['location'] ?? 'Location not available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildStatusBadge(status, paymentStatus),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                booking['dates'] ?? 'Dates not available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.person, color: Colors.grey.shade600, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                booking['guests'] ?? 'Guests not specified',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.bed, color: Colors.grey.shade600, size: 14),
            const SizedBox(width: 4),
            Text(
              booking['roomType'] ?? 'Room',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.totalPrice ?? 'Total Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatPrice(booking['price'] ?? '0'),
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
            if (hotelData.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)?.viewDetails ?? 'View Details',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, String paymentStatus) {
    Color statusColor;
    String statusText;
    
    if (status == 'confirmed') {
      statusColor = Colors.green;
      statusText = AppLocalizations.of(context)?.confirmed ?? 'Confirmed';
    } else if (status == 'pending') {
      statusColor = Colors.orange;
      statusText = AppLocalizations.of(context)?.pending ?? 'Pending';
    } else {
      statusColor = Colors.grey;
      statusText = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  String _formatPrice(String price) {
    try {
      final amount = int.parse(price);
      if (amount >= 100000) {
        return '${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}K';
      }
      return amount.toString();
    } catch (e) {
      return price;
    }
  }
}
