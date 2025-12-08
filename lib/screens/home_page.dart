import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/hotel_service.dart';
import '../l10n/app_localizations.dart';
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
  final TextEditingController _adultsController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
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
    _adultsController.text = '1';
    _childrenController.text = '0';
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
    if (!mounted) return;
    setState(() {
      _isLoadingHotels = true;
    });

    try {
      final response = await HotelService.getHotels();
      if (!mounted) return;
      
      if (response.data != null && response.data is List) {
        final hotels = response.data as List;
        setState(() {
          _hotels = hotels.map((hotel) {
            // Parse location
            String locationString = AppLocalizations.of(context)?.locationNotAvailable ?? 'Location not available';
            final location = hotel['location'];
            if (location != null && location is Map) {
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

            // Parse images
            String? imageUrl;
            final images = hotel['images'] ?? [];
            if (images.isNotEmpty) {
              final firstImage = images[0];
              if (firstImage is String) {
                imageUrl = firstImage;
              } else if (firstImage is Map && firstImage['url'] != null) {
                imageUrl = firstImage['url'].toString();
              }
            }

            // Parse rating
            double rating = 0.0;
            final ratingData = hotel['rating'];
            if (ratingData != null && ratingData is Map) {
              rating = (ratingData['average'] ?? 0.0).toDouble();
            }

            // Parse amenities (can be array of strings or objects)
            List<dynamic> amenities = [];
            final hotelAmenities = hotel['amenities'] ?? [];
            if (hotelAmenities is List) {
              amenities = hotelAmenities.map((item) {
                if (item is String) {
                  return item;
                } else if (item is Map && item['name'] != null) {
                  return item['name'];
                }
                return item.toString();
              }).toList();
            }

            // Parse contact
            final contact = hotel['contact'] ?? {};

            // Parse price
            final hotelPrice = _getPriceValue(
              hotel['discountedPrice'] ?? 
              hotel['price'] ?? 
              hotel['basePrice'] ?? 
              0
            );

            return {
              'id': hotel['_id'] ?? '',
              'name': hotel['name'] ?? '',
              'location': locationString,
              'price': hotelPrice == 0 ? '0' : hotelPrice.toStringAsFixed(0),
              'rating': rating,
              'image': imageUrl ?? 'assets/images/sri.jpg',
              'description': hotel['description'] ?? '',
              'amenities': amenities,
              'contact': contact,
              'hotelData': Map<String, dynamic>.from(hotel),
            };
          }).toList();
          _isLoadingHotels = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingHotels = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingHotels = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _locationController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 580,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeaderSection(),
                  Positioned(
                    top: 150,
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
                    '${AppLocalizations.of(context)?.hey ?? 'Hey'} ${_userName ?? 'User'} 👋',
                    style: TextStyle(
                      color: AppColors.gradientStart,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.letsStartJourney ?? "Let's start your journey!",
                    style: const TextStyle(
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
                child: _buildAdultsField(),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildChildrenField(),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildDateField(),
          const SizedBox(height: 15),
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
                  : Text(
                      AppLocalizations.of(context)?.search ?? 'Search',
                      style: const TextStyle(
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
        Text(
          AppLocalizations.of(context)?.location ?? 'Location',
          style: const TextStyle(
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
                    hintText: AppLocalizations.of(context)?.enterYourDestination ?? 'Enter your destination',
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
        Text(
          AppLocalizations.of(context)?.date ?? 'Date',
          style: const TextStyle(
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
                                : AppLocalizations.of(context)?.selectDate ?? 'Select Date',
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

  Widget _buildAdultsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.adults ?? 'Adults',
          style: const TextStyle(
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
                  controller: _adultsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.adults ?? 'Adults',
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

  Widget _buildChildrenField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.children ?? 'Children',
          style: const TextStyle(
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
              Icon(Icons.child_care, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _childrenController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.children ?? 'Children',
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
    if (!mounted) return;
    setState(() {
      _isSearching = true;
    });

    try {
      final city = _locationController.text.trim();
      final adults = int.tryParse(_adultsController.text) ?? 1;
      final children = int.tryParse(_childrenController.text) ?? 0;
      
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

      if (!mounted) return;

      List<Map<String, dynamic>> searchResults = [];

      if (response.data != null && response.data is List) {
        final rooms = response.data as List;
        searchResults = rooms.map((room) {
          // Handle hotel data
          final hotel = room['hotelId'];
          String hotelName = 'Hotel Name';
          String hotelId = '';
          Map<String, dynamic> hotelData = {};
          String locationString = AppLocalizations.of(context)?.locationNotAvailable ?? 'Location not available';
          double rating = 0.0;
          
          if (hotel != null && hotel is Map) {
            hotelId = hotel['_id'] ?? '';
            hotelName = hotel['name'] ?? 'Hotel Name';
            hotelData = Map<String, dynamic>.from(hotel);
            
            // Parse location
            final location = hotel['location'];
            if (location != null && location is Map) {
              final cityName = location['city'] ?? '';
              final state = location['state'] ?? '';
              final address = location['address'] ?? '';
              if (cityName.isNotEmpty && state.isNotEmpty) {
                locationString = '$cityName, $state';
              } else if (cityName.isNotEmpty) {
                locationString = cityName;
              } else if (state.isNotEmpty) {
                locationString = state;
              } else if (address.isNotEmpty) {
                locationString = address;
              }
            }
            
            // Parse rating
            final ratingData = hotel['rating'];
            if (ratingData != null && ratingData is Map) {
              rating = (ratingData['average'] ?? 0.0).toDouble();
            }
          }

          // Handle room images (room has images array, not hotel)
          String? imageUrl;
          final roomImages = room['images'] ?? [];
          if (roomImages.isNotEmpty) {
            final firstImage = roomImages[0];
            if (firstImage is String) {
              imageUrl = firstImage;
            } else if (firstImage is Map && firstImage['url'] != null) {
              imageUrl = firstImage['url'].toString();
            }
          }
          
          // If no room images, try hotel images
          if (imageUrl == null && hotel != null && hotel is Map) {
            final hotelImages = hotel['images'] ?? [];
            if (hotelImages.isNotEmpty) {
              final firstImage = hotelImages[0];
              if (firstImage is String) {
                imageUrl = firstImage;
              } else if (firstImage is Map && firstImage['url'] != null) {
                imageUrl = firstImage['url'].toString();
              }
            }
          }

          // Calculate price
          final basePrice = room['basePrice'] ?? 0;
          final taxRate = room['taxRate'] ?? 0;
          final taxAmount = (basePrice * taxRate / 100);
          final finalPrice = basePrice + taxAmount;

          // Room details
          final roomType = room['type'] ?? 'Room';
          final capacity = room['capacity'] ?? {};
          final roomAmenities = room['amenities'] ?? [];
          final description = room['description'] ?? '';
          final cancellationRules = room['cancellationRules'] ?? {};

          return {
            'id': hotelId.isNotEmpty ? hotelId : (room['_id'] ?? ''),
            'name': hotelName,
            'location': locationString,
            'price': finalPrice.toStringAsFixed(0),
            'basePrice': basePrice.toString(),
            'discountedPrice': finalPrice.toStringAsFixed(0),
            'originalPrice': finalPrice.toStringAsFixed(0),
            'rating': rating,
            'image': imageUrl ?? 'assets/images/sri.jpg',
            'description': description.isNotEmpty ? description : (hotelData['description'] ?? ''),
            'amenities': roomAmenities.isNotEmpty ? roomAmenities : (hotelData['amenities'] ?? []),
            'roomType': roomType,
            'capacity': capacity,
            'cancellationRules': cancellationRules,
            'hotelData': hotelData.isNotEmpty ? hotelData : {},
            'roomData': room,
          };
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });

      if (!mounted) return;

      final searchParams = {
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'adults': adults,
        'children': children,
        'city': city,
      };
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            searchResults: searchResults,
            searchQuery: city.isNotEmpty ? city : 'Search',
            searchParams: searchParams,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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

  String _getLocalizedFilter(String filter) {
    final localizations = AppLocalizations.of(context);
    switch (filter) {
      case 'All':
        return localizations?.all ?? 'All';
      case 'AC Room':
        return localizations?.acRoom ?? 'AC Room';
      case '4 Stars':
        return localizations?.fourStars ?? '4 Stars';
      case 'Near Me':
        return localizations?.nearMe ?? 'Near Me';
      case 'Mans':
        return localizations?.mans ?? 'Mans';
      case 'Luxury':
        return localizations?.luxury ?? 'Luxury';
      case 'Budget':
        return localizations?.budget ?? 'Budget';
      default:
        return filter;
    }
  }

  Widget _getImageWidget(dynamic imageData) {
    String imagePath = 'assets/images/sri.jpg';
    
    if (imageData != null) {
      if (imageData is String) {
        imagePath = imageData;
      } else if (imageData is Map) {
        imagePath = imageData['url']?.toString() ?? 
                   imageData['image']?.toString() ?? 
                   imageData['src']?.toString() ?? 
                   'assets/images/sri.jpg';
      } else {
        imagePath = imageData.toString();
      }
    }

    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return Image.network(
        imagePath,
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
      );
    } else {
      return Image.asset(
        imagePath,
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
      );
    }
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
                  _getLocalizedFilter(_filters[index]),
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
              Text(
                AppLocalizations.of(context)?.hotelNearYou ?? 'Hotel Near You',
                style: const TextStyle(
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
                  ? Center(child: Text(AppLocalizations.of(context)?.noHotelsAvailable ?? 'No hotels available'))
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
        final hotelWithSearch = Map<String, dynamic>.from(hotel);
        hotelWithSearch['searchParams'] = {
          'checkInDate': _checkInDate,
          'checkOutDate': _checkOutDate,
          'adults': int.tryParse(_adultsController.text) ?? 1,
          'children': int.tryParse(_childrenController.text) ?? 0,
        };
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HotelDetailPage(hotel: hotelWithSearch),
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
            _getImageWidget(hotel['image']),
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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

  double _getPriceValue(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      // Remove commas and Rs prefix
      final cleaned = price.replaceAll(RegExp(r'[Rs,\s]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}

