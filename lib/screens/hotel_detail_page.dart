import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/hotel_service.dart';
import 'booking_selection_page.dart';

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
  final List<String> _galleryImages = const [
    'assets/images/booking.jpg',
    'assets/images/sri.jpg',
    'assets/images/loginbg.png',
    'assets/images/booking.jpg',
    'assets/images/sri.jpg',
  ];

  List<Map<String, dynamic>> _recommendedHotels = [];
  bool _isLoadingRecommended = true;
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoadingRooms = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedHotels();
    _loadHotelRooms();
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
    setState(() {
      _isLoadingRecommended = true;
    });

    try {
      final response = await HotelService.getRandomHotels();
      if (response.data != null && response.data is List) {
        final hotels = response.data as List;
        setState(() {
          _recommendedHotels = hotels.map((hotel) {
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
          _isLoadingRecommended = false;
        });
      } else {
        setState(() {
          _isLoadingRecommended = false;
        });
      }
    } catch (e) {
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
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final imageUrl = widget.hotel['image'] ?? 'assets/images/booking.jpg';
    return Container(
      height: 400,
      width: double.infinity,
      child: imageUrl.toString().startsWith('http')
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
                        const SizedBox(height: 20),
                        _buildHotelInfo(),
                        const SizedBox(height: 20),
                        _buildRoomsSection(),
                        const SizedBox(height: 20),
                        _buildDescription(),
                        const SizedBox(height: 20),
                        _buildGallery(),
                        const SizedBox(height: 20),
                        _buildOwnerSection(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special offer only for you',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
            const SizedBox(width: 4),
            const Text(
              '40%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 15),
            Text(
              'Rs 5,999',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Rs 480/night',
              style: TextStyle(
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

  Widget _buildHotelInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hotel['name'] ?? 'Sri Rangandha Nilayam',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.hotel['location'] ?? 'Sriangam, tamil nadu',
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
                  widget.hotel['rating']?.toString() ?? '4.8',
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
              '549 reviews',
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
    final basePrice = room['basePrice'] ?? 0;
    final taxRate = room['taxRate'] ?? 0;
    final finalPrice = basePrice + (basePrice * taxRate / 100);
    final roomType = room['type'] ?? 'Standard';
    final description = room['description'] ?? '';
    final amenities = room['amenities'] ?? [];
    final images = room['images'] ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : null;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        roomType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '₹${finalPrice.toStringAsFixed(0)}/night',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
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
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _galleryImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Owner',
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
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 30, color: AppColors.red),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parkash Raj',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.white, size: 24),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.white, size: 24),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HotelDetailPage(
                                  hotel: _recommendedHotels[index],
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
                const Text(
                  'Rs 4,599',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingSelectionPage(hotel: widget.hotel),
                  ),
                );
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
}

