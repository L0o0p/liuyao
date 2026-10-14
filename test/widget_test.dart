import 'package:flutter_test/flutter_test.dart';

import 'package:liuyao/main.dart';

void main() {
  testWidgets('应用可以打开学习页', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('六爻基础'), findsOneWidget);
    expect(find.text('学习'), findsOneWidget);
  });
}
