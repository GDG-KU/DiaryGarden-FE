import 'dart:convert';
import 'dart:typed_data';

import 'package:diary_garden/data/datasource/local_diary_entries.dart';
import 'package:diary_garden/presentation/features/diary/diary_read_page.dart';
import 'package:diary_garden/presentation/features/diary/diary_write_page.dart';
import 'package:diary_garden/presentation/features/forest/garden_main_page.dart';
import 'package:diary_garden/presentation/features/forest/my_forest_page.dart';
import 'package:diary_garden/presentation/features/home/home_page.dart';
import 'package:diary_garden/presentation/features/main/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final asset = _assets[key];
    if (asset == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(asset));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final asset = _assets[key];
    if (asset == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return asset;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });

  Widget _buildApp(Widget child, {AssetBundle? bundle}) {
    return MaterialApp(
      builder: (context, baseChild) {
        final appChild = baseChild ?? const SizedBox.shrink();
        if (bundle == null) {
          return appChild;
        }
        return DefaultAssetBundle(bundle: bundle, child: appChild);
      },
      home: child,
    );
  }

  AssetBundle _svgBundle() {
    const simpleSvg = '''
<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">
  <rect width="10" height="10" fill="#8BC68B"/>
</svg>
''';
    return _FakeAssetBundle({
      'assets/trees/flower_tree.svg': simpleSvg,
      'assets/trees/bubble_tree.svg': simpleSvg,
    });
  }

  group('MainPage', () {
    testWidgets('opens write modal when action button tapped', (tester) async {
      await tester.pumpWidget(_buildApp(const MainPage()));

      expect(find.bySemanticsLabel('write_button'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('write_button'));
      await tester.pumpAndSettle();

      expect(find.text('제목'), findsOneWidget);
      expect(find.text('본문'), findsOneWidget);
    });
  });

  group('DiaryReadPage', () {
    testWidgets('renders list of local diary entries', (tester) async {
      await tester.pumpWidget(_buildApp(DiaryReadPage()));

      expect(find.text('일기 읽기'), findsOneWidget);
      expect(find.text(localDiaryEntries.first.title), findsOneWidget);
    });
  });

  group('DiaryWritePage', () {
    testWidgets('renders form fields for writing diary', (tester) async {
      await tester.pumpWidget(_buildApp(const DiaryWritePage()));

      expect(find.text('일기 쓰기'), findsOneWidget);
      expect(find.text('날짜'), findsOneWidget);
      expect(find.text('제목'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);
    });
  });

  group('Home and Garden flow', () {
    testWidgets('home route shows garden summary directly', (tester) async {
      await tester.pumpWidget(
        _buildApp(const HomePage(), bundle: _svgBundle()),
      );

      expect(find.text('나의 숲'), findsOneWidget);
      expect(find.text('최고 기록: 00일'), findsOneWidget);
      expect(find.text('누적 나무 수: 00그루'), findsOneWidget);
    });

    testWidgets('garden page shows summary and analysis guide', (tester) async {
      await tester.pumpWidget(
        _buildApp(const GardenMainPage(), bundle: _svgBundle()),
      );

      expect(find.text('나의 숲'), findsOneWidget);
      expect(find.text('최고 기록: 00일'), findsOneWidget);
      expect(find.textContaining('일기 분포'), findsOneWidget);
    });
  });

  group('MyForestPage', () {
    testWidgets('loads year view grid after data fetch', (tester) async {
      await tester.pumpWidget(
        _buildApp(const MyForestPage(initialMode: ViewMode.year)),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('나의 숲'), findsOneWidget);
      expect(find.text('1월'), findsOneWidget);
    });
  });
}
