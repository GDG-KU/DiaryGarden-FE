import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로그인 예제',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 앱이 시작될 때 보여줄 페이지를 '/login'으로 설정합니다.
      initialRoute: '/login',
      // 페이지 이동을 위한 '이름이 있는 경로(routes)'를 설정합니다.
      routes: {'/login': (context) => LoginPage()},
    );
  }
}

// --- 1. 로그인 페이지 ---
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이디 입력 필드
            TextField(
              decoration: InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            // 비밀번호 입력 필드
            TextField(
              obscureText: true, // 비밀번호 가리기
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            // 로그인 버튼
            ElevatedButton(
              onPressed: () {
                // 임시 로그인: 바로 홈으로 이동
                Navigator.pushReplacementNamed(context, '/main');
              },
              child: Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. 홈페이지 ---
