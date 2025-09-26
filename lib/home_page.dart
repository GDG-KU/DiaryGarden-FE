import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dairy Gardening')),
      body: const Center(
        child: Text('홈페이지입지다', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
