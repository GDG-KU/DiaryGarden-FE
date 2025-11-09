import 'package:flutter_test/flutter_test.dart';

import 'package:diary_garden/main.dart';

void main() {
  testWidgets('앱이 처음에 로그인 페이지를 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsAtLeastNWidgets(1));
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsWidgets);
  });
}
