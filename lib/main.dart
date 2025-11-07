import 'package:diary_garden/login_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart'; // ✅ 여기서 불러오기

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Dairy Garden',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LoginPage(), // ✅ 처음 실행할 때 보여줄 페이지
    );
  }
}
