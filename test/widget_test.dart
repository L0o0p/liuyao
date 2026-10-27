import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/study_groups.dart';
import 'package:liuyao/main.dart';
import 'package:liuyao/models/srs_card.dart';
import 'package:liuyao/screens/chapter_detail_screen.dart';
import 'package:liuyao/screens/study_session_screen.dart';
import 'package:liuyao/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('应用默认打开今日学习，页签是今日、章节、我的', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await settle(tester);

    expect(find.text('今日学习'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
    expect(find.text('章节'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('学习'), findsNothing);
    expect(find.text('图鉴'), findsNothing);
    expect(find.text('进度'), findsNothing);
  });

  testWidgets('今日页显示今天的小组，开始后先看小组引入页，再逐条做选择题', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await settle(tester);

    expect(find.text('今天新学：五行相生（5 条）'), findsOneWidget);
    await tester.tap(find.text('开始学习'));
    await settle(tester);
    await settle(tester);

    expect(find.text('今日新学'), findsOneWidget);
    expect(find.text('五行相生'), findsOneWidget);
    expect(find.text('木生火，火生土，土生金，金生水，水生木。'), findsOneWidget);
    expect(find.text('记住了，开始答题'), findsNothing);

    await tester.tap(find.text('开始逐条练习'));
    await settle(tester);

    expect(find.textContaining('所生的是什么五行？'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(4));
    expect(find.text('记住了，开始答题'), findsNothing);
  });

  testWidgets('今天的小组引入过后不再自动引入，可以再学一组', (WidgetTester tester) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'srs_daily': jsonEncode({
        'date': StorageService.dayStamp(now),
        'groups': ['wuxing_sheng'],
      }),
      for (final key in StudyGroups.byId('wuxing_sheng')!.itemKeys)
        'srs:$key': jsonEncode(
          SrsCard(
            itemKey: key,
            state: SrsState.review,
            dueAt: now.add(const Duration(days: 1)),
            intervalDays: 1,
            updatedAt: 1,
          ).toJson(),
        ),
    });
    await tester.pumpWidget(const MyApp());
    await settle(tester);

    expect(find.text('今天已经学完'), findsOneWidget);
    expect(find.text('今天的新组已经学过'), findsOneWidget);
    await tester.tap(find.text('再学一组：五行相克（5 条）'));
    await settle(tester);
    await settle(tester);

    expect(find.text('五行相克'), findsOneWidget);
    expect(find.text('开始逐条练习'), findsOneWidget);
  });

  testWidgets('章节按学习顺序列出，点进去能看到对照表和练习入口', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await settle(tester);

    await tester.tap(find.text('章节'));
    await settle(tester);

    expect(find.text('五行生克'), findsOneWidget);
    expect(find.text('天干'), findsOneWidget);
    expect(find.text('地支'), findsOneWidget);
    expect(find.text('天干地支基础'), findsNothing);
    expect(find.text('综合练习'), findsNothing);
    final first = tester.getTopLeft(find.text('五行生克')).dy;
    final second = tester.getTopLeft(find.text('天干')).dy;
    final third = tester.getTopLeft(find.text('地支')).dy;
    expect(first, lessThan(second));
    expect(second, lessThan(third));

    await tester.ensureVisible(find.text('地支'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('地支'));
    await settle(tester);

    expect(find.text('地支属性'), findsOneWidget);
    expect(find.text('十二支指诀'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('练这一章'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ChapterDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('练这一章'), findsOneWidget);
  });

  testWidgets('做题时查表打开本章对照表，返回后还在原题', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionScreen(
          title: '测试',
          loadItemKeys: () async => ['gan_wuxing:甲'],
        ),
      ),
    );
    await settle(tester);

    expect(find.text('记住了，开始答题'), findsOneWidget);
    await tester.tap(find.text('查表'));
    await tester.pumpAndSettle();
    expect(find.text('天干属性'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('记住了，开始答题'), findsOneWidget);

    await tester.tap(find.text('记住了，开始答题'));
    await settle(tester);
    final wrong = ['火', '土', '金', '水'].firstWhere(
      (option) =>
          find.widgetWithText(ElevatedButton, option).evaluate().isNotEmpty,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, wrong));
    await settle(tester);
    expect(find.text('错误'), findsOneWidget);

    final lookup = find.widgetWithText(OutlinedButton, '查表');
    await tester.ensureVisible(lookup);
    await tester.tap(lookup);
    await tester.pumpAndSettle();
    expect(find.text('天干属性'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('错误'), findsOneWidget);
    expect(find.text('下一题'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('答错不增加总题数，做完计划里的题就结束', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionScreen(
          title: '判断旺相',
          loadItemKeys: () async => ['wangxiang:旺', 'wangxiang:相'],
        ),
      ),
    );
    await settle(tester);

    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.text('记住了，开始答题'));
    await settle(tester);
    expect(find.text('1/2'), findsOneWidget);

    const states = ['旺', '相', '休', '囚', '死'];
    final wrong = states.firstWhere(
      (option) =>
          option != '旺' &&
          find.widgetWithText(ElevatedButton, option).evaluate().isNotEmpty,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, wrong));
    await settle(tester);
    expect(find.text('错误'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    final next = find.text('下一题');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await settle(tester);
    expect(find.text('2/2'), findsOneWidget);

    await tester.tap(find.text('记住了，开始答题'));
    await settle(tester);
    expect(find.text('2/2'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, '相'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('本次练完了'), findsOneWidget);
    expect(find.text('3/2'), findsNothing);
    expect(find.text('2/3'), findsNothing);
  });

  testWidgets('我的页有连续学习、整体掌握度和导入导出', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await settle(tester);

    await tester.tap(find.text('我的'));
    await settle(tester);

    expect(find.text('连续学习 0 天', findRichText: true), findsOneWidget);
    expect(find.text('整体掌握度'), findsOneWidget);
    expect(find.text('导出学习数据'), findsOneWidget);
    expect(find.text('导入学习数据'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('清空全部卡片'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('清空全部卡片'), findsOneWidget);
  });
}
