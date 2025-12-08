import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../l10n/app_localizations.dart';
import '../services/hotel_service.dart';
import '../services/auth_service.dart';
import 'hotel_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final List<Map<String, dynamic>> _favoriteHotels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final response = await HotelService.getFavorites(userId);
      
      if (response.data != null && response.data['success'] == true) {
        final favoriteIds = response.data['favorites'] as List<dynamic>? ?? [];
        
        // Fetch all hotels and filter by favorite IDs
        final allHotelsResponse = await HotelService.getHotels();
        final List<Map<String, dynamic>> hotels = [];
        
        if (allHotelsResponse.data != null && allHotelsResponse.data is List) {
          final allHotels = allHotelsResponse.data as List;
          
          for (var favoriteId in favoriteIds) {
            try {
              final hotel = allHotels.firstWhere(
                (h) => (h['_id'] ?? h['id']).toString() == favoriteId.toString(),
                orElse: () => null,
              );
              
              if (hotel == null) continue;
              
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

              hotels.add({
                'id': hotel['_id'] ?? hotel['id'] ?? favoriteId.toString(),
                'name': hotel['name'] ?? '',
                'location': locationString,
                'image': imageUrl ?? 'assets/images/sri.jpg',
                'rating': hotel['rating'],
                'hotelData': hotel,
              });
            } catch (e) {
              // Skip hotels that fail to load
              continue;
            }
          }
        }

        if (mounted) {
          setState(() {
            _favoriteHotels.clear();
            _favoriteHotels.addAll(hotels);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load favorites';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading favorites: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _removeFavorite(String hotelId) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) {
        _showSnackBar('User not logged in');
        return;
      }

      await HotelService.removeFromFavorites(userId, hotelId);
      
      // Remove from local list
      setState(() {
        _favoriteHotels.removeWhere((hotel) => hotel['id'] == hotelId);
      });

      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)?.removedFromFavorites ?? 'Removed from favorites');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to remove: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _favoriteHotels.isEmpty
                          ? _buildEmptyState()
                          : _buildFavoritesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        AppLocalizations.of(context)?.myFavorites ?? 'My Favorites',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)?.noFavoritesYet ?? 'No Favorites Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)?.startAddingFavorites ?? 'Start adding hotels to your favorites',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemCount: _favoriteHotels.length,
      itemBuilder: (context, index) {
        return _buildFavoriteCard(_favoriteHotels[index]);
      },
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HotelDetailPage(hotel: hotel),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _getImageWidget(
                    hotel['image'] ?? hotel['hotelData']?['images']?[0],
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(width: 12),
                // Hotel Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel Name and Favorite Icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hotel['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.red,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final hotelId = hotel['id'] ?? hotel['hotelData']?['_id'] ?? '';
                              if (hotelId.isNotEmpty) {
                                _removeFavorite(hotelId.toString());
                              }
                            },
                            child: const Icon(
                              Icons.favorite,
                              color: AppColors.red,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hotel['location'] ?? AppLocalizations.of(context)?.locationNotAvailable ?? 'Location not available',
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
                      const SizedBox(height: 8),
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.gradientStart,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRating(hotel).toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${_getReviewCount(hotel)} ${AppLocalizations.of(context)?.reviews ?? 'reviews'})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Book Now Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HotelDetailPage(hotel: hotel),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.bookNow ?? 'Book Now',
                            style: const TextStyle(
                              fontSize: 14,
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
          ),
        ),
      ),
    );
  }

  Widget _getImageWidget(dynamic imageData, {double? width, double? height}) {
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

    final isNetworkImage = imagePath.startsWith('http://') || imagePath.startsWith('https://');
    
    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/sri.jpg',
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
            'assets/images/sri.jpg',
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        },
      );
    }
  }

  double _getRating(Map<String, dynamic> hotel) {
    final hotelData = hotel['hotelData'] ?? hotel;
    final rating = hotel['rating'] ?? hotelData['rating'];
    
    if (rating is num) {
      return rating.toDouble();
    } else if (rating is Map) {
      return (rating['average'] ?? 0.0).toDouble();
    } else if (rating is String) {
      return double.tryParse(rating) ?? 0.0;
    }
    return 0.0;
  }

  int _getReviewCount(Map<String, dynamic> hotel) {
    final hotelData = hotel['hotelData'] ?? hotel;
    final rating = hotel['rating'] ?? hotelData['rating'];
    
    if (rating is Map && rating['totalReviews'] != null) {
      return (rating['totalReviews'] as num).toInt();
    }
    
    final reviews = hotelData['reviews'] ?? [];
    if (reviews is List) {
      return reviews.length;
    }
    
    return 0;
  }

  String _getPrice(Map<String, dynamic> hotel) {
    final hotelData = hotel['hotelData'] ?? hotel;
    final price = hotel['discountedPrice'] ?? 
                  hotel['price'] ?? 
                  hotelData['discountedPrice'] ?? 
                  hotelData['price'] ?? 
                  0;
    
    if (price is num) {
      return price == 0 ? '0' : price.toStringAsFixed(0);
    } else if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[Rs,\s]'), '');
      final numValue = double.tryParse(cleaned) ?? 0;
      return numValue == 0 ? '0' : numValue.toStringAsFixed(0);
    }
    return '0';
  }
}

