// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:chatappdemo1/main.dart';

void main() {
  testWidgets('App shows Login page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // 期望初始页面包含“登录”标题
    expect(find.text('登录'), findsOneWidget);
  });
}
