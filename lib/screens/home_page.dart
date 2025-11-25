import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/hotel_service.dart';
import 'hotel_detail_page.dart';
import 'search_results_page.dart';
import 'checkout_page.dart' show DatePickerBottomSheet;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _guestController = TextEditingController();
  int _selectedFilterIndex = 0;
  DateTime? _selectedDate;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _userName;
  final List<String> _filters = ['All', 'AC Room', '4 Stars', 'Near Me', 'Mans', 'Luxury', 'Budget'];
  List<Map<String, dynamic>> _hotels = [];
  bool _isLoadingHotels = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _guestController.text = '1';
    _loadUserName();
    _loadHotels();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name ?? 'User';
      });
    }
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoadingHotels = true;
    });

    try {
      final response = await HotelService.getRandomHotels();
      if (response.data != null && response.data is List) {
        final hotels = response.data as List;
        setState(() {
          _hotels = hotels.map((hotel) {
            final location = hotel['location'] ?? {};
            final city = location['city'] ?? '';
            final state = location['state'] ?? '';
            final locationString = city.isNotEmpty && state.isNotEmpty
                ? '$city, $state'
                : city.isNotEmpty
                    ? city
                    : state.isNotEmpty
                        ? state
                        : 'Location not available';

            final images = hotel['images'] ?? [];
            final imageUrl = images.isNotEmpty ? images[0] : null;

            return {
              'id': hotel['_id'] ?? '',
              'name': hotel['name'] ?? 'Hotel Name',
              'location': locationString,
              'price': '4,800',
              'rating': hotel['rating']?['average'] ?? 0.0,
              'image': imageUrl ?? 'assets/images/sri.jpg',
              'description': hotel['description'] ?? '',
              'amenities': hotel['amenities'] ?? [],
              'hotelData': hotel,
            };
          }).toList();
          _isLoadingHotels = false;
        });
      } else {
        setState(() {
          _isLoadingHotels = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingHotels = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _locationController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 500,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeaderSection(),
                  Positioned(
                    top: 160,
                    left: 0,
                    right: 0,
                    child: _buildSearchForm(),
                  ),
                ],
              ),
            ),
                        const SizedBox(height: 20),

            _buildHotelSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/loginbg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 70,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey ${_userName ?? 'User'} 👋',
                    style: TextStyle(
                      color: AppColors.gradientStart,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Let's start your journey!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationField(),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildDateField(),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildGuestField(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ElevatedButton(
              onPressed: _isSearching ? null : _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                      ),
                    )
                  : const Text(
                      'Search',
                      style: TextStyle(
                        color: Color(0xFF8B4513),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFilterButtons(),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Enter your destination',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showDatePicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _checkInDate != null && _checkOutDate != null
                        ? '${_getMonthName(_checkInDate!.month)} ${_checkInDate!.day} - ${_getMonthName(_checkOutDate!.month)} ${_checkOutDate!.day}'
                        : _checkInDate != null
                            ? '${_getMonthName(_checkInDate!.month)} ${_checkInDate!.day}, ${_checkInDate!.year}'
                            : _selectedDate != null
                                ? '${_getMonthName(_selectedDate!.month)} ${_selectedDate!.day}, ${_selectedDate!.year}'
                                : 'Select Date',
                    style: TextStyle(
                      color: (_checkInDate != null || _selectedDate != null) ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guest',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _guestController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: 'Add guest',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DatePickerBottomSheet(
        checkInDate: _checkInDate ?? _selectedDate,
        checkOutDate: _checkOutDate,
        onDatesSelected: (checkIn, checkOut) {
          setState(() {
            _checkInDate = checkIn;
            _checkOutDate = checkOut;
            _selectedDate = checkIn; // Keep for backward compatibility
          });
        },
      ),
    );
  }

  Future<void> _performSearch() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final city = _locationController.text.trim();
      final guestCount = int.tryParse(_guestController.text) ?? 0;
      final adults = guestCount; // Assuming all guests are adults for now
      final children = 0;
      
      String? startDateStr;
      String? endDateStr;
      
      if (_checkInDate != null) {
        startDateStr = '${_checkInDate!.year}-${_checkInDate!.month.toString().padLeft(2, '0')}-${_checkInDate!.day.toString().padLeft(2, '0')}';
      }
      if (_checkOutDate != null) {
        endDateStr = '${_checkOutDate!.year}-${_checkOutDate!.month.toString().padLeft(2, '0')}-${_checkOutDate!.day.toString().padLeft(2, '0')}';
      }

      final response = await HotelService.getAllRooms(
        city: city.isNotEmpty ? city : null,
        adults: adults > 0 ? adults : null,
        children: children > 0 ? children : null,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      List<Map<String, dynamic>> searchResults = [];

      if (response.data != null && response.data is List) {
        final rooms = response.data as List;
        searchResults = rooms.map((room) {
          final hotel = room['hotelId'] ?? {};
          final location = hotel['location'] ?? {};
          final cityName = location['city'] ?? '';
          final state = location['state'] ?? '';
          final locationString = cityName.isNotEmpty && state.isNotEmpty
              ? '$cityName, $state'
              : cityName.isNotEmpty
                  ? cityName
                  : state.isNotEmpty
                      ? state
                      : 'Location not available';

          final images = hotel['images'] ?? [];
          final imageUrl = images.isNotEmpty ? images[0] : null;

          final basePrice = room['basePrice'] ?? 0;
          final taxRate = room['taxRate'] ?? 0;
          final finalPrice = basePrice + (basePrice * taxRate / 100);

          return {
            'id': hotel['_id'] ?? '',
            'name': hotel['name'] ?? 'Hotel Name',
            'location': locationString,
            'price': finalPrice.toStringAsFixed(0),
            'discountedPrice': finalPrice.toStringAsFixed(0),
            'originalPrice': (basePrice * 1.3).toStringAsFixed(0), // Simulated original price
            'discount': '30%',
            'rating': hotel['rating']?['average'] ?? 0.0,
            'image': imageUrl ?? 'assets/images/sri.jpg',
            'description': hotel['description'] ?? '',
            'amenities': hotel['amenities'] ?? [],
            'hotelData': hotel,
            'roomData': room,
          };
        }).toList();
      }

      setState(() {
        _isSearching = false;
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            searchResults: searchResults,
            searchQuery: city.isNotEmpty ? city : 'Search',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching: ${e.toString()}'),
          backgroundColor: AppColors.red,
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

  Widget _buildFilterButtons() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.red : AppColors.gradientStart,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHotelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hotel Near You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.offset - 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: AppColors.gradientStart,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.offset + 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 280,
          child: _isLoadingHotels
              ? const Center(child: CircularProgressIndicator())
              : _hotels.isEmpty
                  ? const Center(child: Text('No hotels available'))
                  : ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _hotels.length,
                      itemBuilder: (context, index) {
                        return _buildHotelCard(_hotels[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HotelDetailPage(hotel: hotel),
          ),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
          children: [
            hotel['image'].toString().startsWith('http')
                ? Image.network(
                    hotel['image'],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/sri.jpg',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    hotel['image'] ?? 'assets/images/sri.jpg',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel['location'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${hotel['price']}/night',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.gradientStart,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hotel['rating'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

