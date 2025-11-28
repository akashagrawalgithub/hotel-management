import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../l10n/app_localizations.dart';
import '../services/hotel_service.dart';
import '../services/auth_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _todayNotifications = [];
  List<Map<String, dynamic>> _yesterdayNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await HotelService.getNotifications(userId);
      
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final notifications = response.data as List;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          final todayList = <Map<String, dynamic>>[];
          final yesterdayList = <Map<String, dynamic>>[];

          for (var notification in notifications) {
            final notificationData = _parseNotification(notification);
            
            if (notification['createdAt'] != null) {
              try {
                final createdAt = DateTime.parse(notification['createdAt']);
                final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
                
                if (notificationDate == today) {
                  todayList.add(notificationData);
                } else if (notificationDate == yesterday) {
                  yesterdayList.add(notificationData);
                }
              } catch (e) {
                // If date parsing fails, add to today's list
                todayList.add(notificationData);
              }
            } else {
              todayList.add(notificationData);
            }
          }

          setState(() {
            _todayNotifications = todayList;
            _yesterdayNotifications = yesterdayList;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseNotification(Map<String, dynamic> notification) {
    final type = notification['type']?.toString().toLowerCase() ?? '';
    final title = notification['message'] ?? notification['title'] ?? 'Notification';
    final createdAt = notification['createdAt'] ?? notification['createdAt'] ?? '';
    
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    if (type.contains('hotel') || type.contains('room') || type.contains('accommodation')) {
      icon = Icons.hotel;
      iconColor = Colors.green;
      iconBgColor = Colors.green;
    } else if (type.contains('discount') || type.contains('offer') || type.contains('deal')) {
      icon = Icons.local_offer;
      iconColor = Colors.blue;
      iconBgColor = Colors.blue;
    } else if (type.contains('booking') || type.contains('reservation') || type.contains('success')) {
      icon = Icons.celebration;
      iconColor = Colors.orange;
      iconBgColor = Colors.lightBlue;
    } else if (type.contains('payment') || type.contains('transaction')) {
      icon = Icons.shopping_cart;
      iconColor = Colors.blue;
      iconBgColor = Colors.lightBlue;
    } else if (type.contains('breakfast') || type.contains('food') || type.contains('restaurant')) {
      icon = Icons.restaurant;
      iconColor = Colors.orange;
      iconBgColor = Colors.orange;
    } else {
      icon = Icons.notifications;
      iconColor = Colors.grey;
      iconBgColor = Colors.grey;
    }

    String timeAgo = 'Just now';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays > 0) {
          timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        } else if (difference.inHours > 0) {
          timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        } else if (difference.inMinutes > 0) {
          timeAgo = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
        }
      } catch (e) {
        timeAgo = 'Recently';
      }
    }

    return {
      'icon': icon,
      'iconColor': iconColor,
      'iconBgColor': iconBgColor,
      'title': title,
      'time': timeAgo,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_todayNotifications.isEmpty && _yesterdayNotifications.isEmpty)
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_todayNotifications.isNotEmpty)
                        _buildSection(
                          AppLocalizations.of(context)?.today ?? 'Today',
                          _todayNotifications,
                        ),
                      if (_yesterdayNotifications.isNotEmpty)
                        _buildSection(
                          AppLocalizations.of(context)?.yesterday ?? 'Yesterday',
                          _yesterdayNotifications,
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)?.noNotifications ?? 'No notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.noNotificationsMessage ?? 'You\'re all caught up!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
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
      title: Text(
        AppLocalizations.of(context)?.notification ?? 'Notification',
        style: const TextStyle(
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

