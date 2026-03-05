import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gongter/router.dart';
import 'package:gongter/services/supabase_service.dart';

/// Top-level handler for background messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'gongter_notifications',
    '공터 알림',
    description: '댓글, 대댓글, 공지사항 알림',
    importance: Importance.high,
  );

  /// Initialize FCM: request permission, save token, set up listeners.
  static Future<void> initialize() async {
    // Request permission (iOS required, Android 13+ optional)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Initialize local notifications
    await _initLocalNotifications();

    // Get and save FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When user taps notification to open app (from background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was launched from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Subscribe to announcements topic
    await _messaging.subscribeToTopic('announcements');
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _saveToken(String token) async {
    debugPrint('[FCM] Token: $token');
    try {
      await SupabaseService.saveFcmToken(token);
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Tapped: ${message.data}');
    _navigateFromPayload(message.data);
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[Local] Tapped: ${response.payload}');
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromPayload(data);
    } catch (e) {
      debugPrint('[Local] Failed to parse payload: $e');
    }
  }

  static void _navigateFromPayload(Map<String, dynamic> data) {
    final targetType = data['target_type'] as String?;
    final targetId = data['target_id'] as String?;
    if (targetType == 'post' && targetId != null) {
      appRouter.push('/post/$targetId');
    }
  }

  /// Unsubscribe from topics (call on logout)
  static Future<void> cleanup() async {
    await _messaging.unsubscribeFromTopic('announcements');
  }
}
