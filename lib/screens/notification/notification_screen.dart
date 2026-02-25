import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('알림이 없습니다',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['is_read'] as bool? ?? false;
                      return ListTile(
                        tileColor: isRead ? null : AppColors.primary.withValues(alpha: 0.05),
                        leading: Icon(
                          _getIcon(n['type'] as String?),
                          color: isRead
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                        title: Text(n['title'] as String? ?? ''),
                        subtitle: Text(
                          timeago.format(
                            DateTime.parse(n['created_at'] as String),
                            locale: 'ko',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () async {
                          await SupabaseService.markNotificationRead(
                              n['id'] as String);
                          final targetType = n['target_type'] as String?;
                          final targetId = n['target_id'] as String?;
                          if (targetType == 'post' && targetId != null) {
                            if (context.mounted) context.push('/post/$targetId');
                          }
                          if (mounted) await _loadNotifications();
                        },
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'comment':
        return Icons.chat_bubble_outline;
      case 'like':
        return Icons.favorite_outline;
      case 'report_result':
        return Icons.gavel;
      default:
        return Icons.notifications;
    }
  }
}
