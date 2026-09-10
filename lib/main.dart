import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/paint_estimate_calculator_screen.dart';
import 'services/estimate_storage_service.dart';
import 'theme/paint_estimate_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await EstimateStorageService.init();
  runApp(const PaintEstimateApp());
}

/// Root app shell — Gwinn Painting Solutions brand theme.
class PaintEstimateApp extends StatelessWidget {
  const PaintEstimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gwinn Painting Solutions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: PaintEstimateTheme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PaintEstimateTheme.midnightNavy,
          primary: PaintEstimateTheme.midnightNavy,
          secondary: PaintEstimateTheme.warmGold,
          onPrimary: PaintEstimateTheme.white,
          surface: PaintEstimateTheme.background,
          onSurface: PaintEstimateTheme.charcoal,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: PaintEstimateTheme.midnightNavy,
          foregroundColor: PaintEstimateTheme.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: PaintEstimateTheme.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: PaintEstimateTheme.charcoal.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: PaintEstimateTheme.charcoal.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: PaintEstimateTheme.warmGold,
              width: 2,
            ),
          ),
          labelStyle: GoogleFonts.plusJakartaSans(
            color: PaintEstimateTheme.charcoal.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: PaintEstimateTheme.midnightNavy,
            foregroundColor: PaintEstimateTheme.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PaintEstimateTheme.midnightNavy,
            side: const BorderSide(color: PaintEstimateTheme.warmGold, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
      home: const PaintEstimateCalculatorScreen(),
    );
  }
}
