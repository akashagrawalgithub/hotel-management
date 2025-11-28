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
    setState(() {
      _isLoading = true;
      _isLoadingHistory = true;
    });

    try {
      final email = await AuthService.getUserEmail();
      if (email != null && email.isNotEmpty) {
        final response = await HotelService.getBookingHistory(email);
        if (response.data != null && response.data is List) {
          final bookings = response.data as List;
          setState(() {
            _bookings = bookings.map((booking) {
              final hotel = booking['hotelId'] ?? {};
              final location = hotel['location'] ?? {};
              final city = location['city'] ?? '';
              final state = location['state'] ?? '';
              final locationString = city.isNotEmpty && state.isNotEmpty
                  ? '$city, $state'
                  : city.isNotEmpty
                      ? city
                      : state.isNotEmpty
                          ? state
                          : AppLocalizations.of(context)?.locationNotAvailable ?? 'Location not available';

              final images = hotel['images'] ?? [];
              final imageUrl = images.isNotEmpty ? images[0] : null;

              final checkIn = booking['checkIn'] != null
                  ? DateTime.parse(booking['checkIn'])
                  : null;
              final checkOut = booking['checkOut'] != null
                  ? DateTime.parse(booking['checkOut'])
                  : null;

              String datesString = AppLocalizations.of(context)?.datesNotAvailable ?? 'Dates not available';
              if (checkIn != null && checkOut != null) {
                final monthNames = [
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
                datesString =
                    '${checkIn.day} - ${checkOut.day} ${monthNames[checkOut.month - 1]} ${checkOut.year}';
              }

              final guestCount = booking['guestCount'] ?? 1;
              final roomCount = booking['roomCount'] ?? 1;
              final localizations = AppLocalizations.of(context);
              final guestText = guestCount > 1 
                  ? (localizations?.guests ?? 'Guests')
                  : (localizations?.guest ?? 'Guest');
              final roomText = roomCount > 1
                  ? (localizations?.rooms ?? 'Rooms')
                  : (localizations?.room ?? 'Room');
              final guestsString = '$guestCount $guestText ($roomCount $roomText)';

              return {
                'id': booking['_id'] ?? '',
                'name': hotel['name'] ?? 'Hotel Name',
                'rating': hotel['rating']?['average'] ?? 0.0,
                'location': locationString,
                'price': booking['totalPrice']?.toString() ?? '0',
                'dates': datesString,
                'guests': guestsString,
                'image': imageUrl ?? 'assets/images/booking.jpg',
                'hotelData': hotel,
                'bookingData': booking,
              };
            }).toList();
            _historyBookings = List.from(_bookings);
            _isLoading = false;
            _isLoadingHistory = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _isLoadingHistory = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
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
                  AppLocalizations.of(context)?.booked ?? 'Booked',
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
                  AppLocalizations.of(context)?.history ?? 'History',
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookings.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)?.noBookingsFound ?? 'No bookings found'));
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyBookings.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)?.noBookingHistoryFound ?? 'No booking history found'));
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
    return GestureDetector(
      onTap: () {
        final hotelForDetail = {
          'id': hotelData['_id'] ?? booking['id'] ?? '',
          'name': hotelData['name'] ?? booking['name'] ?? 'Hotel Name',
          'location': booking['location'] ?? 'Location not available',
          'price': booking['price'] ?? '0',
          'rating': hotelData['rating']?['average'] ?? booking['rating'] ?? 0.0,
          'image': booking['image'] ?? 'assets/images/booking.jpg',
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
        child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: booking['image'].toString().startsWith('http')
                  ? Image.network(
                      booking['image'],
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/booking.jpg',
                          width: 120,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      booking['image'] ?? 'assets/images/booking.jpg',
                      width: 120,
                      fit: BoxFit.cover,
                    ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.gradientStart, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        booking['rating'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking['location'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Rs ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        booking['price'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.red,
                        ),
                      ),
                      Text(
                        ' ${AppLocalizations.of(context)?.night ?? '/night'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${AppLocalizations.of(context)?.dates ?? 'Dates'} ${booking['dates']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${AppLocalizations.of(context)?.guest ?? 'Guest'} ${booking['guests']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
      ),
    );
  }
}

