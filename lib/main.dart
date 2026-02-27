import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/router.dart';
import 'package:gongter/services/ad_service.dart';
import 'package:gongter/services/notification_service.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init (skip gracefully if config files not yet added)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Init skipped: $e');
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Cache profile completion for sync router redirect
  await SupabaseService.checkProfileComplete();

  // FCM token registration (after Supabase init & auth check)
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('[FCM] Init skipped: $e');
  }

  await AdService.initialize();

  // Register Korean locale for timeago
  timeago.setLocaleMessages('ko', timeago.KoMessages());

  runApp(const GongterApp());
}

/// Request ATT permission (iOS only, after first frame)
Future<void> _requestATT() async {
  if (!Platform.isIOS) return;
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

class GongterApp extends StatefulWidget {
  const GongterApp({super.key});

  @override
  State<GongterApp> createState() => _GongterAppState();
}

class _GongterAppState extends State<GongterApp> {
  @override
  void initState() {
    super.initState();
    // ATT must be called after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestATT());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '공터',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
