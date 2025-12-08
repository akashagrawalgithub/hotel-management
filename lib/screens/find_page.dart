import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/hotel_service.dart';
import '../l10n/app_localizations.dart';
import 'notification_page.dart';
import 'hotel_detail_page.dart';

class FindPage extends StatefulWidget {
  final VoidCallback? onBackPressed;
  
  const FindPage({super.key, this.onBackPressed});

  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _recommendedScrollController = ScrollController();

  List<Map<String, dynamic>> _bestMatches = [];
  List<Map<String, dynamic>> _recommendedHotels = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _recommendedScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHotels() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await HotelService.getHotels();
      if (!mounted) return;
      
      if (response.data != null && response.data is List) {
        final hotels = response.data as List;
        setState(() {
          _bestMatches = hotels.map((hotel) {
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

            // Parse amenities
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

            return {
              'id': hotel['_id'] ?? '',
              'name': hotel['name'] ?? '',
              'location': locationString,
              'image': imageUrl ?? 'assets/images/booking.jpg',
              'description': hotel['description'] ?? '',
              'rating': rating,
              'amenities': amenities,
              'contact': contact,
              'hotelData': Map<String, dynamic>.from(hotel),
            };
          }).toList();
          
          _recommendedHotels.clear();
          _recommendedHotels.addAll(_bestMatches);
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearchMode = false;
        _searchResults.clear();
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _isSearchMode = true;
    });

    try {
      final response = await HotelService.searchHotels(query.trim());
      if (!mounted) return;

      // Debug: Print response
      print('Search response status: ${response.statusCode}');
      print('Search response data: ${response.data}');

      // Check if response has data
      if (response.data != null) {
        final responseData = response.data;
        
        // Check if success is true
        if (responseData['success'] == true) {
          final hotels = responseData['hotels'] ?? [];
          print('Found ${hotels.length} hotels');
          
          if (!mounted) return;
          
          try {
            final mappedHotels = hotels.map<Map<String, dynamic>>((hotel) {
              final location = hotel['location'];
              String locationString;
              if (location != null && location is Map && location.isNotEmpty) {
                final city = location['city'] ?? '';
                final state = location['state'] ?? '';
                locationString = city.isNotEmpty && state.isNotEmpty
                    ? '$city, $state'
                    : city.isNotEmpty
                        ? city
                        : state.isNotEmpty
                            ? state
                            : AppLocalizations.of(context)?.locationNotAvailable ?? 'Location not available';
              } else {
                locationString = AppLocalizations.of(context)?.locationNotAvailable ?? 'Location not available';
              }

              final images = hotel['images'] ?? [];
              String? imageUrl;
              if (images.isNotEmpty) {
                final firstImage = images[0];
                if (firstImage is String) {
                  imageUrl = firstImage;
                } else if (firstImage is Map && firstImage['url'] != null) {
                  imageUrl = firstImage['url'].toString();
                }
              }

              return {
                'id': hotel['_id'] ?? '',
                'name': hotel['name'] ?? '',
                'location': locationString,
                'image': imageUrl ?? 'assets/images/booking.jpg',
                'description': hotel['description'] ?? '',
                'rating': hotel['rating']?['average'] ?? 0.0,
                'amenities': hotel['amenities'] ?? [],
                'hotelData': hotel,
              };
            }).toList();
            
            print('Mapped ${mappedHotels.length} hotels');
            
            if (!mounted) return;
            setState(() {
              _searchResults = mappedHotels;
              _isSearching = false;
            });
            
            print('Search results set: ${_searchResults.length}');
          } catch (e, stackTrace) {
            print('Error mapping hotels: $e');
            print('Stack trace: $stackTrace');
            if (!mounted) return;
            setState(() {
              _searchResults = [];
              _isSearching = false;
            });
          }
        } else {
          // Success is false or not present
          if (!mounted) return;
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } else {
        // No data in response
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: ${e.toString()}'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9E0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isSearchMode)
                      _buildSearchResultsSection()
                    else ...[
                      _buildBestMatchSection(),
                      _buildRecommendedSection(),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)?.search ?? 'Search',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 20,
              ),
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
      ),
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
                      _isSearchMode = false;
                      _searchResults.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) {
          _performSearch(value);
        },
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildBestMatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            AppLocalizations.of(context)?.bestMatchForYou ?? 'Best match for you',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_bestMatches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                AppLocalizations.of(context)?.noHotelsAvailable ?? 'No hotels available',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _bestMatches.length,
            itemBuilder: (context, index) {
              return _buildBestMatchCard(_bestMatches[index]);
            },
          ),
      ],
    );
  }

  Widget _getImageWidget(dynamic imageData, {double? width, double? height}) {
    String imagePath = 'assets/images/booking.jpg';
    
    if (imageData != null) {
      if (imageData is String) {
        imagePath = imageData;
      } else if (imageData is Map) {
        imagePath = imageData['url']?.toString() ?? 
                   imageData['image']?.toString() ?? 
                   imageData['src']?.toString() ?? 
                   'assets/images/booking.jpg';
      } else {
        imagePath = imageData.toString();
      }
    }

    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
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
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.hotel,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }

  Widget _buildBestMatchCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () {
        final hotelWithContact = Map<String, dynamic>.from(hotel);
        // Ensure contact info is passed
        if (hotel['hotelData'] != null && hotel['hotelData']['contact'] != null) {
          hotelWithContact['contact'] = hotel['hotelData']['contact'];
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HotelDetailPage(hotel: hotelWithContact),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: _getImageWidget(hotel['image'], width: 100, height: 130),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hotel['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel['location'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
              ),
            ),
          )
        else if (_searchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)?.noResultsFound ?? 'No results found',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.tryDifferentKeywords ?? 'Try searching with different keywords',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Text(
              '${_searchResults.length} ${AppLocalizations.of(context)?.resultsFound ?? 'results found'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildBestMatchCard(_searchResults[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            AppLocalizations.of(context)?.recommendedForYou ?? 'Recommended for You',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
            controller: _recommendedScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _recommendedHotels.length,
            itemBuilder: (context, index) {
              return _buildRecommendedCard(_recommendedHotels[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () {
        final hotelWithContact = Map<String, dynamic>.from(hotel);
        // Ensure contact info is passed
        if (hotel['hotelData'] != null && hotel['hotelData']['contact'] != null) {
          hotelWithContact['contact'] = hotel['hotelData']['contact'];
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HotelDetailPage(hotel: hotelWithContact),
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
