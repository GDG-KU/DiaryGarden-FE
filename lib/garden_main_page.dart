// lib/pages/garden_main_page.dart
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'my_forest_page.dart'; // 월/년 캘린더 화면(앞서 만든 페이지)

class GardenMainPage extends StatelessWidget {
  const GardenMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    const offWhite = Color(0xFFFAF6EE);
    const lawn = Color(0xFF8BC68B);

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: offWhite,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('나의 숲'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz),
            onSelected: (v) {
              final mode = v == 'month' ? ViewMode.month : ViewMode.year;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyForestPage(initialMode: mode),
                ),
              );
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'month', child: Text('월 보기(캘린더)')),
              PopupMenuItem(value: 'year', child: Text('년 보기(캘린더)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 요약(최고 기록/누적 나무 수)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: const [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '최고 기록: 00일',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '누적 나무 수: 00그루',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '월 / 년',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // 정원(일러스트) 영역
          Expanded(
            child: Stack(
              children: [
                // 잔디 배경
                Positioned.fill(
                  child: Column(
                    children: [
                      const Expanded(flex: 12, child: SizedBox()),
                      Expanded(flex: 16, child: Container(color: lawn)),
                    ],
                  ),
                ),
                // 큰 나무
                Positioned(
                  right: 28,
                  bottom: 60,
                  child: SizedBox(
                    width: 160,
                    child: SvgPicture.asset(
                      'assets/trees/flower_tree.svg',
                      semanticsLabel: 'flower tree',
                    ),
                  ),
                ),
                // 둥근 나무
                Positioned(
                  left: 28,
                  bottom: 48,
                  child: SizedBox(
                    width: 160,
                    child: SvgPicture.asset(
                      'assets/trees/bubble_tree.svg',
                      semanticsLabel: 'bubble tree',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 하단 분석 안내
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Text(
              '일기 분포 (무슨 요일 많이 쓰는지, 어떤 감정이 많은지 등 추세로 알려줄게)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
