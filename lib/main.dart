import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:diary_garden/presentation/features/home/home_page.dart';
import 'package:diary_garden/presentation/features/login/login_page.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/tree_vector_util_test_page.dart';

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
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/test': (context) => const TreeVectorUtilTestPage(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Dairy Garden',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const TreeVectorUtilTestPage(), // 🧪 Testing TreeVectorUtil
    );
  }
}
