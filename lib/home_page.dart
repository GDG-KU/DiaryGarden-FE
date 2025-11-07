// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'garden_main_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
}
