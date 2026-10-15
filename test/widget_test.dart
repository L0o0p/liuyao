import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('应用默认打开今日学习', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('今日学习'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
    expect(find.text('学习'), findsOneWidget);
    expect(find.text('进度'), findsOneWidget);
    expect(find.text('复习'), findsNothing);
  });
}