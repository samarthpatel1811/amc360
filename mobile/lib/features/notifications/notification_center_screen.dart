import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/notifications');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final data = res.data['data'];
        setState(() {
          _unreadCount = data['unread_count'] ?? 0;
          _notifications = data['notifications']?['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await _api.post('/notifications/$id/read');
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.post('/notifications/read-all');
      _fetchNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Loading notification alerts...');
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _fetchNotifications);
    }

    if (_notifications.isEmpty) {
      return const EmptyState(
        title: 'No Notifications',
        message: 'You have no alerts at this time. All schedules, renewals and jobs are in sync.',
        icon: Icons.notifications_none_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          final id = item['id'];
          final title = item['title'] ?? 'Notice';
          final message = item['message'] ?? '';
          final isRead = item['is_read'] == true;
          final createdAt = item['created_at'];

          String timeAgo = '';
          if (createdAt != null) {
            final dt = DateTime.tryParse(createdAt);
            if (dt != null) timeAgo = DateFormat('dd MMM, hh:mm a').format(dt);
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: isRead ? null : () => _markAsRead(id),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRead ? Colors.transparent : AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
