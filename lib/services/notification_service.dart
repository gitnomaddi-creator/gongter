import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gongter/services/supabase_service.dart';

/// Top-level handler for background messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system notification tray.
  // No action needed here unless custom processing is required.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

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
    // Foreground messages don't show system notification by default.
    // The in-app notification list (notifications table) handles this.
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Tapped: ${message.data}');
    // Navigation is handled by deep link or GoRouter.
    // Data payload should contain target_type and target_id.
  }
}
