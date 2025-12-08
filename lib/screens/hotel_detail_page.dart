import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/hotel_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'booking_selection_page.dart';
import 'checkout_page.dart' show DatePickerBottomSheet;

class HotelDetailPage extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailPage({
    super.key,
    required this.hotel,
  });

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  List<String> _galleryImages = [];

  List<Map<String, dynamic>> _recommendedHotels = [];
  bool _isLoadingRecommended = true;
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoadingRooms = true;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  bool _hasContactInfo() {
    final contact = widget.hotel['contact'] ?? widget.hotel['hotelData']?['contact'] ?? {};
    return (contact['phone'] != null && contact['phone'].toString().isNotEmpty) ||
           (contact['email'] != null && contact['email'].toString().isNotEmpty) ||
           (contact['website'] != null && contact['website'].toString().isNotEmpty);
  }

  double _getRating() {
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final rating = widget.hotel['rating'] ?? hotelData['rating'];
    
    if (rating is num) {
      return rating.toDouble();
    } else if (rating is Map) {
      return (rating['average'] ?? 0.0).toDouble();
    } else if (rating is String) {
      return double.tryParse(rating) ?? 0.0;
    }
    return 0.0;
  }

  int _getReviewCount() {
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final rating = widget.hotel['rating'] ?? hotelData['rating'];
    
    if (rating is Map && rating['totalReviews'] != null) {
      return (rating['totalReviews'] as num).toInt();
    }
    
    final reviews = hotelData['reviews'] ?? [];
    if (reviews is List) {
      return reviews.length;
    }
    
    return 0;
  }

  double _getPriceFromHotel(Map<String, dynamic> hotel) {
    final hotelData = hotel['hotelData'] ?? hotel;
    final price = hotel['discountedPrice'] ?? hotel['price'] ?? hotelData['discountedPrice'] ?? hotelData['price'];
    return _getPriceValue(price);
  }

  double _getTotalPrice() {
    // Get base price from hotel
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final price = _getPriceValue(
      widget.hotel['discountedPrice'] ?? 
      widget.hotel['price'] ?? 
      hotelData['discountedPrice'] ?? 
      hotelData['price']
    );
    
    // If we have rooms, try to get price from first room
    if (price == 0 && _rooms.isNotEmpty) {
      final firstRoom = _rooms[0];
      final basePrice = _getPriceValue(firstRoom['basePrice']);
      final taxRate = _getPriceValue(firstRoom['taxRate']);
      if (basePrice > 0) {
        return basePrice + (basePrice * taxRate / 100);
      }
    }
    
    return price;
  }

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
    _loadRecommendedHotels();
    _loadHotelRooms();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) return;

      final hotelId = widget.hotel['_id'] ?? 
                      widget.hotel['id'] ?? 
                      widget.hotel['hotelData']?['_id'] ?? '';
      if (hotelId.isEmpty) return;

      final response = await HotelService.getFavorites(userId);
      if (response.data != null && response.data['success'] == true) {
        final favorites = response.data['favorites'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _isFavorite = favorites.contains(hotelId.toString());
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          _showSnackBar('Please login to add favorites');
        }
        setState(() {
          _isLoadingFavorite = false;
        });
        return;
      }

      final hotelId = widget.hotel['_id'] ?? 
                      widget.hotel['id'] ?? 
                      widget.hotel['hotelData']?['_id'] ?? '';
      if (hotelId.isEmpty) {
        setState(() {
          _isLoadingFavorite = false;
        });
        return;
      }

      if (_isFavorite) {
        await HotelService.removeFromFavorites(userId, hotelId.toString());
        if (mounted) {
          _showSnackBar(AppLocalizations.of(context)?.removedFromFavorites ?? 'Removed from favorites');
        }
      } else {
        await HotelService.addToFavorites(userId, hotelId.toString());
        if (mounted) {
          _showSnackBar(AppLocalizations.of(context)?.addedToFavorites ?? 'Added to favorites');
        }
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}');
        setState(() {
          _isLoadingFavorite = false;
        });
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

  void _loadGalleryImages() {
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final images = hotelData['images'] ?? [];
    
    _galleryImages = [];
    if (images.isNotEmpty) {
      for (var image in images) {
        if (image is String) {
          _galleryImages.add(image);
        } else if (image is Map && image['url'] != null) {
          _galleryImages.add(image['url'].toString());
        }
      }
    }
  }

  Future<void> _loadHotelRooms() async {
    setState(() {
      _isLoadingRooms = true;
    });

    try {
      final hotelId = widget.hotel['id'] ?? widget.hotel['_id'] ?? widget.hotel['hotelData']?['_id'];
      if (hotelId != null && hotelId.toString().isNotEmpty) {
        final response = await HotelService.getHotelRooms(hotelId.toString());
        if (response.data != null && response.data['success'] == true) {
          final rooms = response.data['rooms'] as List? ?? [];
          setState(() {
            _rooms = rooms.map((room) => room as Map<String, dynamic>).toList();
            _isLoadingRooms = false;
          });
        } else {
          setState(() {
            _isLoadingRooms = false;
          });
        }
      } else {
        setState(() {
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRooms = false;
      });
    }
  }

  Future<void> _loadRecommendedHotels() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRecommended = true;
    });

    try {
      final response = await HotelService.getHotels();
      if (!mounted) return;
      
      if (response.data != null && response.data is List) {
        final hotels = response.data as List;
        setState(() {
          _recommendedHotels = hotels.map((hotel) {
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

            // Get price from hotel data
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
              'price': hotelPrice == 0 ? '0' : hotelPrice.toString(),
              'rating': rating,
              'image': imageUrl ?? 'assets/images/sri.jpg',
              'description': hotel['description'] ?? '',
              'amenities': amenities,
              'contact': contact,
              'hotelData': Map<String, dynamic>.from(hotel),
            };
          }).toList();
          _isLoadingRecommended = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingRecommended = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRecommended = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildImageSection(),
          _buildContentSection(context),
          _buildBackButton(context),
          _buildFavoriteButton(context),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final imageData = widget.hotel['image'];
    String imageUrl = 'assets/images/booking.jpg';
    
    if (imageData != null) {
      if (imageData is String) {
        imageUrl = imageData;
      } else if (imageData is Map) {
        imageUrl = imageData['url']?.toString() ?? 
                   imageData['image']?.toString() ?? 
                   imageData['src']?.toString() ?? 
                   'assets/images/booking.jpg';
      } else {
        imageUrl = imageData.toString();
      }
    }
    
    final isNetworkImage = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    
    return Container(
      height: 400,
      width: double.infinity,
      child: isNetworkImage
          ? Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/booking.jpg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            )
          : Image.asset(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/booking.jpg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: _isLoadingFavorite
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? AppColors.red : Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: _toggleFavorite,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSpecialOffer(),
                        if (widget.hotel['searchParams'] != null) ...[
                          const SizedBox(height: 20),
                          _buildSearchParamsSection(),
                        ],
                        const SizedBox(height: 20),
                        _buildHotelInfo(),
                        const SizedBox(height: 20),
                        _buildRoomsSection(),
                        if (widget.hotel['description'] != null && widget.hotel['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildDescription(),
                        ],
                        const SizedBox(height: 20),
                        _buildGallery(),
                        if (_hasContactInfo()) ...[
                          const SizedBox(height: 20),
                          _buildOwnerSection(),
                        ],
                        const SizedBox(height: 20),
                        _buildRecommendedSection(context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSpecialOffer() {
    // Get pricing data
    final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
    final discountedPrice = _getPriceValue(widget.hotel['discountedPrice'] ?? hotelData['discountedPrice'] ?? widget.hotel['price'] ?? hotelData['price']);
    final originalPrice = _getPriceValue(widget.hotel['originalPrice'] ?? hotelData['originalPrice']);
    final discount = widget.hotel['discount'] ?? hotelData['discount'];
    
    // Calculate discount percentage if we have both prices
    String discountPercent = '0%';
    if (originalPrice > 0 && discountedPrice > 0 && originalPrice > discountedPrice) {
      final discountValue = ((originalPrice - discountedPrice) / originalPrice * 100).round();
      discountPercent = '$discountValue%';
    } else if (discount != null) {
      discountPercent = discount.toString().contains('%') ? discount.toString() : '$discount%';
    }

    final hasDiscount = (originalPrice > 0 && discountedPrice > 0 && originalPrice > discountedPrice) || (discount != null && discountPercent != '0%');

    if (!hasDiscount && discountedPrice == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.specialOfferOnlyForYou ?? 'Special offer only for you',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (hasDiscount) ...[
              const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
              const SizedBox(width: 4),
              Text(
                discountPercent,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 15),
            ],
            if (originalPrice > 0 && discountedPrice > 0 && originalPrice > discountedPrice) ...[
              Text(
                '₹ ${_formatPrice(originalPrice)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              '₹ ${_formatPrice(discountedPrice)}/night',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
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

  String _formatPrice(double price) {
    if (price == 0) return '0';
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildHotelInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hotel['name'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.hotel['location'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
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
                const Icon(Icons.star, color: AppColors.gradientStart, size: 20),
                const SizedBox(width: 4),
                Text(
                  _getRating().toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_getReviewCount()} reviews',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Rooms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        if (_isLoadingRooms)
          const Center(child: CircularProgressIndicator())
        else if (_rooms.isEmpty)
          const Text(
            'No rooms available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          )
        else
          ..._rooms.map<Widget>((room) => _buildRoomCard(room)).toList(),
      ],
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final capacity = room['capacity'] ?? {};
    final adults = capacity['adults'] ?? 0;
    final children = capacity['children'] ?? 0;
    final total = capacity['total'] ?? 0;
    final basePrice = _getPriceValue(room['basePrice'] ?? 0);
    final taxRate = _getPriceValue(room['taxRate'] ?? 0);
    final finalPrice = basePrice + (basePrice * taxRate / 100);
    final roomType = room['type'] ?? 'Standard';
    final description = room['description'] ?? '';
    final amenities = room['amenities'] ?? [];
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
    final totalRooms = room['totalRooms'] ?? 0;
    final cancellationRules = room['cancellationRules'] ?? {};
    final isNonRefundable = cancellationRules['nonRefundable'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.toString().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: imageUrl.toString().startsWith('http')
                  ? Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 50, color: Colors.grey),
                        );
                      },
                    )
                  : Image.asset(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 50, color: Colors.grey),
                        );
                      },
                    ),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                // Price Details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Base Price: ₹${basePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tax Rate: ${taxRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total: ₹${finalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.red,
                          ),
                        ),
                        Text(
                          '/night',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRoomInfoItem(Icons.person, '$adults Adults'),
                    const SizedBox(width: 15),
                    if (children > 0) ...[
                      _buildRoomInfoItem(Icons.child_care, '$children Children'),
                      const SizedBox(width: 15),
                    ],
                    _buildRoomInfoItem(Icons.bed, 'Total: $total'),
                  ],
                ),
                const SizedBox(height: 12),
                if (amenities.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: amenities.take(4).map<Widget>((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gradientStart.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          amenity.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isNonRefundable ? Icons.cancel : Icons.check_circle,
                          size: 16,
                          color: isNonRefundable ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isNonRefundable ? 'Non-refundable' : 'Free cancellation',
                          style: TextStyle(
                            fontSize: 12,
                            color: isNonRefundable ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$totalRooms rooms available',
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

  Widget _buildRoomInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Lorem ipsum dolor sit amet consectetur adipiscing elit Ut et massa mi. Aliquam in hendrerit urna.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGallery() {
    if (_galleryImages.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gallery',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _galleryImages.length,
            itemBuilder: (context, index) {
              final imageUrl = _galleryImages[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        )
                      : Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchParamsSection() {
    final searchParams = widget.hotel['searchParams'] as Map<String, dynamic>?;
    if (searchParams == null) return const SizedBox.shrink();

    final checkIn = searchParams['checkInDate'] as DateTime?;
    final checkOut = searchParams['checkOutDate'] as DateTime?;
    final adults = searchParams['adults'] ?? 0;
    final children = searchParams['children'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Search Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (checkIn != null && checkOut != null) ...[
            _buildSearchParamRow(Icons.calendar_today, 'Check-in: ${_formatDate(checkIn)}'),
            const SizedBox(height: 8),
            _buildSearchParamRow(Icons.calendar_today, 'Check-out: ${_formatDate(checkOut)}'),
            const SizedBox(height: 8),
          ],
          if (adults > 0) ...[
            _buildSearchParamRow(Icons.person, 'Adults: $adults'),
            if (children > 0) const SizedBox(height: 8),
          ],
          if (children > 0)
            _buildSearchParamRow(Icons.child_care, 'Children: $children'),
        ],
      ),
    );
  }

  Widget _buildSearchParamRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildOwnerSection() {
    final contact = widget.hotel['contact'] ?? widget.hotel['hotelData']?['contact'] ?? {};
    final phone = contact['phone']?.toString() ?? '';
    final email = contact['email']?.toString() ?? '';
    final website = contact['website']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
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
            color: AppColors.red,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              if (phone.isNotEmpty) ...[
                _buildContactRow(Icons.phone, phone, () {
                  // Handle phone call
                }),
                if (email.isNotEmpty || website.isNotEmpty) const SizedBox(height: 12),
              ],
              if (email.isNotEmpty) ...[
                _buildContactRow(Icons.email, email, () {
                  // Handle email
                }),
                if (website.isNotEmpty) const SizedBox(height: 12),
              ],
              if (website.isNotEmpty)
                _buildContactRow(Icons.language, website, () {
                  // Handle website
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended for You',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 280,
          child: _isLoadingRecommended
              ? const Center(child: CircularProgressIndicator())
              : _recommendedHotels.isEmpty
                  ? const Center(child: Text('No recommended hotels available'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommendedHotels.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            final hotel = Map<String, dynamic>.from(_recommendedHotels[index]);
                            // Pass search params if available
                            if (widget.hotel['searchParams'] != null) {
                              hotel['searchParams'] = widget.hotel['searchParams'];
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HotelDetailPage(
                                  hotel: hotel,
                                ),
                              ),
                            );
                          },
                          child: _buildRecommendedCard(_recommendedHotels[index]),
                        );
                      },
                    ),
        ),
      ],
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
    final imageWidth = width ?? double.infinity;
    final imageHeight = height ?? double.infinity;
    
    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/sri.jpg',
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/sri.jpg',
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.cover,
          );
        },
      );
    }
  }

  Widget _buildRecommendedCard(Map<String, dynamic> hotel) {
    return Container(
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
                                (hotel['rating'] ?? 0.0).toString(),
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
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total price',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹ ${_formatPrice(_getTotalPrice())}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                _handleBookNow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Book Now',
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

  void _handleBookNow() async {
    final searchParams = widget.hotel['searchParams'] as Map<String, dynamic>?;
    
    if (searchParams != null && 
        searchParams['checkInDate'] != null && 
        searchParams['checkOutDate'] != null &&
        searchParams['adults'] != null) {
      // Search params exist, always check for rooms first
      final hotelWithParams = Map<String, dynamic>.from(widget.hotel);
      hotelWithParams['searchParams'] = searchParams;
      
      final checkInDate = searchParams['checkInDate'] as DateTime?;
      final checkOutDate = searchParams['checkOutDate'] as DateTime?;
      final adults = searchParams['adults'] as int? ?? 0;
      final children = searchParams['children'] as int? ?? 0;
      
      if (checkInDate != null && checkOutDate != null) {
        // Use rooms from detail page if available, otherwise fetch
        List<Map<String, dynamic>> availableRooms = [];
        
        if (_rooms.isNotEmpty) {
          // Use rooms already loaded in detail page
          // Filter by guest capacity if needed
          availableRooms = _rooms.where((room) {
            final capacity = room['capacity'] ?? {};
            final roomAdults = capacity['adults'] ?? 0;
            final roomChildren = capacity['children'] ?? 0;
            // Check if room can accommodate the guests
            return roomAdults >= adults && (roomChildren >= children || children == 0);
          }).toList();
        } else {
          // Fallback: fetch rooms if not loaded
          final hotelId = widget.hotel['id'] ?? 
                          widget.hotel['_id'] ?? 
                          widget.hotel['hotelData']?['_id'] ?? '';
          final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
          final location = hotelData['location'] ?? {};
          final city = location['city'] ?? '';
          
          // Format dates for API
          final startDate = checkInDate.toUtc().toIso8601String();
          final endDate = checkOutDate.toUtc().toIso8601String();
          
          try {
            final roomsResponse = await HotelService.getAllRooms(
              city: city.isNotEmpty ? city : null,
              adults: adults,
              children: children,
              startDate: startDate,
              endDate: endDate,
            );
            
            if (roomsResponse.data != null && roomsResponse.data is List) {
              final allRooms = roomsResponse.data as List;
              // Filter rooms for this specific hotel
              availableRooms = allRooms
                  .where((room) {
                    final roomHotelId = room['hotelId'];
                    if (roomHotelId is Map) {
                      return (roomHotelId['_id'] ?? '').toString() == hotelId.toString();
                    } else if (roomHotelId is String) {
                      return roomHotelId == hotelId.toString();
                    }
                    return false;
                  })
                  .map((room) => Map<String, dynamic>.from(room))
                  .toList();
            }
          } catch (e) {
            // On error, proceed without room selection
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingSelectionPage(hotel: hotelWithParams),
              ),
            );
            return;
          }
        }
        
        if (availableRooms.isNotEmpty) {
          // Always show room selection, even if only 1 room
          _showRoomSelectionDialog(
            context,
            availableRooms,
            hotelWithParams,
          );
        } else {
          // No rooms available, proceed directly
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingSelectionPage(hotel: hotelWithParams),
            ),
          );
        }
      } else {
        // No dates, show booking details dialog first
        _showBookingDetailsDialog();
      }
    } else {
      // Show dialog to collect booking details
      _showBookingDetailsDialog();
    }
  }

  void _showBookingDetailsDialog() {
    DateTime? checkInDate;
    DateTime? checkOutDate;
    int adults = 0;
    int children = 0;
    final adultsController = TextEditingController(text: '0');
    final childrenController = TextEditingController(text: '0');

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
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.bookNow ?? 'Book Now',
                          style: const TextStyle(
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
                    const SizedBox(height: 24),
                    // Check-in Date
                    Text(
                      AppLocalizations.of(context)?.checkIn ?? 'Check-in Date',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (bottomSheetContext) => DatePickerBottomSheet(
                            checkInDate: checkInDate,
                            checkOutDate: checkOutDate,
                            onDatesSelected: (checkIn, checkOut) {
                              setDialogState(() {
                                checkInDate = checkIn;
                                checkOutDate = checkOut;
                              });
                              // Don't close the bottom sheet automatically
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(
                            color: checkInDate != null ? AppColors.red : Colors.grey.shade300,
                            width: checkInDate != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              checkInDate != null
                                  ? '${checkInDate!.day}/${checkInDate!.month}/${checkInDate!.year}'
                                  : AppLocalizations.of(context)?.selectDate ?? 'Select Date',
                              style: TextStyle(
                                color: checkInDate != null ? Colors.black : Colors.grey.shade600,
                                fontSize: 15,
                                fontWeight: checkInDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: checkInDate != null ? AppColors.red : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Check-out Date
                    Text(
                      AppLocalizations.of(context)?.checkOut ?? 'Check-out Date',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (bottomSheetContext) => DatePickerBottomSheet(
                            checkInDate: checkInDate,
                            checkOutDate: checkOutDate,
                            onDatesSelected: (checkIn, checkOut) {
                              setDialogState(() {
                                checkInDate = checkIn;
                                checkOutDate = checkOut;
                              });
                              // Don't close the bottom sheet automatically
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(
                            color: checkOutDate != null ? AppColors.red : Colors.grey.shade300,
                            width: checkOutDate != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              checkOutDate != null
                                  ? '${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}'
                                  : AppLocalizations.of(context)?.selectDate ?? 'Select Date',
                              style: TextStyle(
                                color: checkOutDate != null ? Colors.black : Colors.grey.shade600,
                                fontSize: 15,
                                fontWeight: checkOutDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: checkOutDate != null ? AppColors.red : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Adults and Children Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)?.adults ?? 'Adults',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: adultsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.red, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                onChanged: (value) {
                                  adults = int.tryParse(value) ?? 0;
                                  if (adults < 0) adults = 0;
                                  setDialogState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)?.children ?? 'Children',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: childrenController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.red, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                onChanged: (value) {
                                  children = int.tryParse(value) ?? 0;
                                  if (children < 0) children = 0;
                                  setDialogState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Action Buttons
                    Row(
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
                            onPressed: checkInDate != null && checkOutDate != null && adults > 0
                                ? () async {
                                    final hotelWithParams = Map<String, dynamic>.from(widget.hotel);
                                    hotelWithParams['searchParams'] = {
                                      'checkInDate': checkInDate,
                                      'checkOutDate': checkOutDate,
                                      'adults': adults,
                                      'children': children,
                                    };
                                    
                                    Navigator.pop(context);
                                    
                                    // Use rooms from detail page if available, filter by guest capacity
                                    List<Map<String, dynamic>> availableRooms = [];
                                    
                                    if (_rooms.isNotEmpty) {
                                      // Use rooms already loaded in detail page
                                      // Filter by guest capacity if needed
                                      availableRooms = _rooms.where((room) {
                                        final capacity = room['capacity'] ?? {};
                                        final roomAdults = capacity['adults'] ?? 0;
                                        final roomChildren = capacity['children'] ?? 0;
                                        // Check if room can accommodate the guests
                                        return roomAdults >= adults && (roomChildren >= children || children == 0);
                                      }).toList();
                                    } else {
                                      // Fallback: fetch rooms if not loaded
                                      final hotelId = widget.hotel['id'] ?? 
                                                      widget.hotel['_id'] ?? 
                                                      widget.hotel['hotelData']?['_id'] ?? '';
                                      final hotelData = widget.hotel['hotelData'] ?? widget.hotel;
                                      final location = hotelData['location'] ?? {};
                                      final city = location['city'] ?? '';
                                      
                                      // Format dates for API
                                      final startDate = checkInDate!.toUtc().toIso8601String();
                                      final endDate = checkOutDate!.toUtc().toIso8601String();
                                      
                                      try {
                                        final roomsResponse = await HotelService.getAllRooms(
                                          city: city.isNotEmpty ? city : null,
                                          adults: adults,
                                          children: children,
                                          startDate: startDate,
                                          endDate: endDate,
                                        );
                                        
                                        if (roomsResponse.data != null && roomsResponse.data is List) {
                                          final allRooms = roomsResponse.data as List;
                                          // Filter rooms for this specific hotel
                                          availableRooms = allRooms
                                              .where((room) {
                                                final roomHotelId = room['hotelId'];
                                                if (roomHotelId is Map) {
                                                  return (roomHotelId['_id'] ?? '').toString() == hotelId.toString();
                                                } else if (roomHotelId is String) {
                                                  return roomHotelId == hotelId.toString();
                                                }
                                                return false;
                                              })
                                              .map((room) => Map<String, dynamic>.from(room))
                                              .toList();
                                        }
                                      } catch (e) {
                                        // On error, proceed without room selection
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookingSelectionPage(hotel: hotelWithParams),
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                    
                                    if (availableRooms.isNotEmpty) {
                                      // Always show room selection, even if only 1 room
                                      _showRoomSelectionDialog(
                                        context,
                                        availableRooms,
                                        hotelWithParams,
                                      );
                                    } else {
                                      // No rooms available, proceed directly
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingSelectionPage(hotel: hotelWithParams),
                                        ),
                                      );
                                    }
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoomSelectionDialog(
    BuildContext context,
    List<Map<String, dynamic>> rooms,
    Map<String, dynamic> hotelWithParams,
  ) {
    // Auto-select if only 1 room
    Map<String, dynamic>? selectedRoom = rooms.length == 1 ? rooms[0] : null;

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
                      final amenities = room['amenities'] ?? [];
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
                                  hotelWithParams['selectedRoom'] = selectedRoom;
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingSelectionPage(hotel: hotelWithParams),
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

