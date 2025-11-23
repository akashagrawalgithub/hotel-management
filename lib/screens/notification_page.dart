import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  final List<Map<String, dynamic>> _todayNotifications = const [
    {
      'icon': Icons.hotel,
      'iconColor': Colors.green,
      'iconBgColor': Colors.green,
      'title': 'Hotel Eliminate Galian has added new accommodation rooms',
      'time': '2 hours Ago',
    },
    {
      'icon': Icons.local_offer,
      'iconColor': Colors.blue,
      'iconBgColor': Colors.blue,
      'title': '20% discount if you stay on Saturday 27 November 2024 at Cerulean Hotel',
      'time': '2 hours Ago',
    },
    {
      'icon': Icons.celebration,
      'iconColor': Colors.orange,
      'iconBgColor': Colors.lightBlue,
      'title': 'Congratulations, you have successfully booked a room at Jade Gem Resort',
      'time': '2 hours Ago',
    },
  ];

  final List<Map<String, dynamic>> _yesterdayNotifications = const [
    {
      'icon': Icons.shopping_cart,
      'iconColor': Colors.blue,
      'iconBgColor': Colors.lightBlue,
      'title': 'Payment has been successfully made, order is being processed',
      'time': '2 hours Ago',
    },
    {
      'icon': Icons.restaurant,
      'iconColor': Colors.orange,
      'iconBgColor': Colors.orange,
      'title': 'Free breakfast at Double Oak Hotel for November 27, 2024',
      'time': '2 hours Ago',
    },
    {
      'icon': Icons.celebration,
      'iconColor': Colors.orange,
      'iconBgColor': Colors.lightBlue,
      'title': 'Congratulations, you have successfully booked a room at Double Oak Hotel',
      'time': '2 hours Ago',
    },
    {
      'icon': Icons.restaurant,
      'iconColor': Colors.orange,
      'iconBgColor': Colors.orange,
      'title': 'Free breakfast at Double Oak Hotel for November 27, 2024',
      'time': '2 hours Ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Today', _todayNotifications),
            _buildSection('Yesterday', _yesterdayNotifications),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
      title: const Text(
        'Notification',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black, size: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationItem(notifications[index]);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (notification['iconBgColor'] as Color).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification['icon'] as IconData,
              color: notification['iconColor'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

