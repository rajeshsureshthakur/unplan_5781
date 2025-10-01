import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './services/supabase_service.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await SupabaseService.initialize();

    // CRITICAL FIX: Enhanced authentication with proper error handling
    final isAuthenticated =
        await SupabaseService.instance.isUserAuthenticated();
    if (!isAuthenticated) {
      print('User not authenticated, attempting demo authentication...');
      // Remove this block - authenticateAsDemoUser method doesn't exist
      // The authentication is already handled within isUserAuthenticated()
    }

    print('✅ App initialization successful');
  } catch (e) {
    print('❌ App initialization failed: $e');

    // CRITICAL FIX: Show configuration error to users
    if (e.toString().contains('Invalid API key') ||
        e.toString().contains('configuration') ||
        e.toString().contains('env.json')) {
      print(
        '🔧 CONFIGURATION REQUIRED: Please update your Supabase credentials in env.json',
      );
      // Continue with app launch but authentication will fail gracefully
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'UnPlan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.homeDashboard,
          routes: AppRoutes.routes,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
