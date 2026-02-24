import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/router.dart';
import 'package:gongter/services/ad_service.dart';
import 'package:gongter/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await AdService.initialize();

  runApp(const ProviderScope(child: GongterApp()));
}

class GongterApp extends StatelessWidget {
  const GongterApp({super.key});

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
