import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'home_page.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.leafGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.leafGreen,
          onPrimary: AppColors.textOnLeaf,
          secondary: AppColors.leafBlue,
          onSecondary: AppColors.textOnLeaf,
          tertiary: AppColors.leafCoral,
          onTertiary: AppColors.textOnLeaf,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
          primaryContainer: AppColors.trunk,
          onPrimaryContainer: AppColors.textOnTrunk,
          secondaryContainer: AppColors.leafYellow,
          onSecondaryContainer: AppColors.textOnLeaf,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diary Garden',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: baseTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.trunk,
          foregroundColor: AppColors.textOnTrunk,
          elevation: 0,
          titleTextStyle: baseTextTheme.titleLarge?.copyWith(
            color: AppColors.textOnTrunk,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: AppColors.textOnTrunk),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.leafCoral,
          foregroundColor: AppColors.textOnLeaf,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.leafYellow.withValues(alpha: 0.3),
          labelStyle: baseTextTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const StadiumBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}
