// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:diary_garden/presentation/features/forest/garden_main_page.dart';

import '../diary/diary_read_page.dart';
import '../diary/diary_write_page.dart';
import '../../../core/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Diary Gardening')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.yard_outlined),
          label: const Text('나의 숲(정원)'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GardenMainPage()),
            );
          },
        ),
      ),
    );
  }

  String _hexWithoutAlpha(Color color) {
    int to8Bit(double channel) => ((channel * 255.0).round()) & 0xff;

    final red = to8Bit(color.r).toRadixString(16).padLeft(2, '0');
    final green = to8Bit(color.g).toRadixString(16).padLeft(2, '0');
    final blue = to8Bit(color.b).toRadixString(16).padLeft(2, '0');
    return '$red$green$blue'.toUpperCase();
  }
}
