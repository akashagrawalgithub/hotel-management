import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../l10n/app_localizations.dart';
import 'hotel_detail_page.dart';

class SearchResultsPage extends StatefulWidget {
  final List<Map<String, dynamic>> searchResults;
  final String searchQuery;
  final Map<String, dynamic>? searchParams;

  const SearchResultsPage({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    this.searchParams,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
          AppLocalizations.of(context)?.searchResults ?? 'Search Results',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: widget.searchResults.isEmpty
          ? _buildEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    '${widget.searchResults.length} ${widget.searchResults.length != 1 ? (AppLocalizations.of(context)?.resultsFoundPlural ?? 'results') : (AppLocalizations.of(context)?.resultsFound ?? 'result')} ${AppLocalizations.of(context)?.found ?? 'found'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: widget.searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildBestMatchCard(widget.searchResults[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)?.noData ?? "We don't have any data",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.tryAdjustingSearch ?? 'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestMatchCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () {
        final hotelWithSearch = Map<String, dynamic>.from(hotel);
        if (widget.searchParams != null) {
          hotelWithSearch['searchParams'] = widget.searchParams;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HotelDetailPage(hotel: hotelWithSearch),
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
              child: hotel['image'] != null &&
                      hotel['image'].toString().startsWith('http')
                  ? Image.network(
                      hotel['image'],
                      width: 100,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/booking.jpg',
                          width: 100,
                          height: 130,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      hotel['image'] ?? 'assets/images/booking.jpg',
                      width: 100,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 130,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.hotel,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
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
                      hotel['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel['location'] ?? AppLocalizations.of(context)?.locationNotAvailable ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (hotel['rating'] != null && hotel['rating'] > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.gradientStart,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hotel['rating'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
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
}

