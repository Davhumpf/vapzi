import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'data/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  NotificationService.instance.init();
  runApp(const VapziApp());
}

class VapziApp extends StatelessWidget {
  const VapziApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Vapzi',
    theme: ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoTransitionBuilder(),
          TargetPlatform.iOS: _NoTransitionBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(),
          side: const BorderSide(color: Color(0xFFBBBBBB)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: const HomeScreen(),
  );
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
