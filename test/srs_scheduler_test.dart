import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao/data/knowledge_catalog.dart';
import 'package:liuyao/models/srs_card.dart';
import 'package:liuyao/services/srs_scheduler.dart';

void main() {
  final now = DateTime(2026, 10, 15, 9);

  SrsCard reviewCard(String itemKey, DateTime dueAt, double intervalDays) {
    return SrsCard(
      itemKey: itemKey,
      state: SrsState.review,
      dueAt: dueAt,
      intervalDays: intervalDays,
      ease: SrsLimits.initialEase,
      reps: 2,
    );
  }

  test('答错后连续一次答对仍留在待清除，第二次才毕业并不再入队', () {
    final card = reviewCard('gan_wuxing:甲', now.add(const Duration(days: 4)), 4);
    expect(
      SrsScheduler.replaysInSession(card: card, correct: false),
      isTrue,
    );
    final wrong = SrsScheduler.grade(
      card: card,
      correct: false,
      elapsed: const Duration(seconds: 3),
      now: now,
    );

    expect(wrong.state, SrsState.learning);
    expect(wrong.intervalDays, 0);
    expect(wrong.lapses, 1);
    expect(wrong.correctStreak, 0);
    expect(wrong.reps, 3);
    expect(wrong.lastReviewedAt, now);
    expect(wrong.dueAt, now.add(const Duration(minutes: 10)));
    expect(wrong.dueAt.isBefore(card.dueAt), isTrue);

    expect(
      SrsScheduler.replaysInSession(card: wrong, correct: true),
      isTrue,
    );
    final once = SrsScheduler.grade(
      card: wrong,
      correct: true,
      elapsed: const Duration(seconds: 9),
      now: now,
    );
    expect(once.state, SrsState.learning);
    expect(once.intervalDays, 0);
    expect(once.lapses, 1);
    expect(once.correctStreak, 1);
    expect(once.reps, 4);
    expect(once.dueAt, wrong.dueAt);
    expect(once.dueAt, isNot(now.add(const Duration(days: 1))));

    expect(
      SrsScheduler.replaysInSession(card: once, correct: true),
      isFalse,
    );
    final recovered = SrsScheduler.grade(
      card: once,
      correct: true,
      elapsed: const Duration(seconds: 3),
      now: now,
    );
    expect(recovered.state, SrsState.review);
    expect(recovered.intervalDays, 1);
    expect(recovered.correctStreak, 2);
    expect(recovered.dueAt, now.add(const Duration(days: 1)));

    final slowGraduation = SrsScheduler.grade(
      card: once,
      correct: true,
      elapsed: const Duration(seconds: 9),
      now: now,
    );
    expect(slowGraduation.state, SrsState.review);
    expect(slowGraduation.intervalDays, 0.5);
    expect(slowGraduation.correctStreak, 2);
  });

  test('连续答对中间再答错会清零，并继续留在队列', () {
    final once = SrsCard(
      itemKey: 'gan_wuxing:甲',
      state: SrsState.learning,
      dueAt: now.add(const Duration(minutes: 10)),
      intervalDays: 0,
      lapses: 1,
      reps: 2,
      correctStreak: 1,
    );

    expect(
      SrsScheduler.replaysInSession(card: once, correct: false),
      isTrue,
    );
    final reset = SrsScheduler.grade(
      card: once,
      correct: false,
      elapsed: const Duration(seconds: 2),
      now: now,
    );
    expect(reset.correctStreak, 0);
    expect(reset.lapses, 2);
    expect(reset.state, SrsState.learning);
    expect(reset.intervalDays, 0);
    expect(reset.dueAt, now.add(const Duration(minutes: 10)));

    expect(
      SrsScheduler.replaysInSession(card: reset, correct: true),
      isTrue,
    );
    final again = SrsScheduler.grade(
      card: reset,
      correct: true,
      elapsed: const Duration(seconds: 2),
      now: now,
    );
    expect(again.correctStreak, 1);
    expect(again.state, SrsState.learning);
    expect(again.intervalDays, 0);
  });

  test('没失误过的卡答对一次就毕业，不再入队', () {
    final introduced = SrsScheduler.introduce('gan_wuxing:甲', now);
    expect(introduced.correctStreak, 0);
    expect(introduced.lapses, 0);
    expect(
      SrsScheduler.replaysInSession(card: introduced, correct: true),
      isFalse,
    );

    final graduated = SrsScheduler.grade(
      card: introduced,
      correct: true,
      elapsed: const Duration(seconds: 5),
      now: now,
    );
    expect(graduated.state, SrsState.review);
    expect(graduated.intervalDays, 1);
    expect(graduated.correctStreak, 1);
    expect(graduated.dueAt, now.add(const Duration(days: 1)));

    final reviewing = reviewCard('gan_wuxing:乙', now, 4);
    expect(
      SrsScheduler.replaysInSession(card: reviewing, correct: true),
      isFalse,
    );
    final extended = SrsScheduler.grade(
      card: reviewing,
      correct: true,
      elapsed: const Duration(seconds: 3),
      now: now,
    );
    expect(extended.intervalDays, 10);
    expect(extended.correctStreak, 1);
    expect(extended.state, SrsState.review);
  });

  test('本次会话里答过错时，即使卡片还没记上 lapses 也要再答一次', () {
    final introduced = SrsScheduler.introduce('gan_wuxing:甲', now);
    expect(
      SrsScheduler.replaysInSession(
        card: introduced,
        correct: true,
        missedInSession: true,
      ),
      isTrue,
    );
    final held = SrsScheduler.grade(
      card: introduced,
      correct: true,
      elapsed: const Duration(seconds: 20),
      now: now,
      missedInSession: true,
    );
    expect(held.state, SrsState.learning);
    expect(held.intervalDays, 0);
    expect(held.correctStreak, 1);
    expect(held.dueAt, introduced.dueAt);

    expect(
      SrsScheduler.replaysInSession(
        card: held,
        correct: true,
        missedInSession: true,
      ),
      isFalse,
    );
    final cleared = SrsScheduler.grade(
      card: held,
      correct: true,
      elapsed: const Duration(seconds: 3),
      now: now,
      missedInSession: true,
    );
    expect(cleared.state, SrsState.review);
    expect(cleared.intervalDays, 1);
    expect(cleared.correctStreak, 2);
  });

  test('旧 JSON 没有 correctStreak 时按 0 读取', () {
    final card = SrsCard.fromJson({
      'itemKey': 'gan_wuxing:甲',
      'state': 'learning',
      'dueAt': 0,
      'intervalDays': 0,
      'lapses': 2,
      'reps': 3,
    });
    expect(card.correctStreak, 0);
    expect(card.toJson()['correctStreak'], 0);

    final kept = card.copyWith(reps: 4);
    expect(kept.correctStreak, 0);
    final marked = card.copyWith(correctStreak: 2);
    expect(marked.correctStreak, 2);
    expect(marked.lapses, 2);
    expect(marked.toJson()['correctStreak'], 2);

    final restored = SrsCard.fromJson(marked.toJson());
    expect(restored.correctStreak, 2);
  });

  test('答对拉长间隔，慢答对增长更少', () {
    final introduced = SrsScheduler.introduce('gan_wuxing:甲', now);
    expect(introduced.state, SrsState.learning);
    expect(introduced.dueAt, now);
    expect(introduced.ease, SrsLimits.initialEase);

    final graduated = SrsScheduler.grade(
      card: introduced,
      correct: true,
      elapsed: const Duration(seconds: 5),
      now: now,
    );
    expect(graduated.state, SrsState.review);
    expect(graduated.intervalDays, 1);
    expect(graduated.dueAt, now.add(const Duration(days: 1)));
    expect(graduated.reps, 1);

    final fast = SrsScheduler.grade(
      card: graduated,
      correct: true,
      elapsed: const Duration(seconds: 8),
      now: now,
    );
    expect(fast.intervalDays, 2.5);
    expect(fast.dueAt, SrsScheduler.addDays(now, 2.5));

    final slow = SrsScheduler.grade(
      card: graduated,
      correct: true,
      elapsed: const Duration(seconds: 8, milliseconds: 1),
      now: now,
    );
    expect(slow.state, SrsState.review);
    expect(slow.intervalDays, 1.75);
    expect(slow.intervalDays, lessThan(fast.intervalDays));

    final slowGraduation = SrsScheduler.grade(
      card: introduced,
      correct: true,
      elapsed: const Duration(seconds: 9),
      now: now,
    );
    expect(slowGraduation.state, SrsState.review);
    expect(slowGraduation.intervalDays, 0.5);

    final capped = SrsScheduler.grade(
      card: reviewCard('gan_wuxing:乙', now, 100),
      correct: true,
      elapsed: const Duration(seconds: 1),
      now: now,
    );
    expect(capped.intervalDays, 180);

    final slowCapped = SrsScheduler.grade(
      card: reviewCard('gan_wuxing:乙', now, 100),
      correct: true,
      elapsed: const Duration(seconds: 20),
      now: now,
    );
    expect(slowCapped.intervalDays, 140);
    expect(slowCapped.state, SrsState.review);
  });

  test('今日队列先到期再新学，新学只取今天这组里还没有卡片的', () {
    final catalog = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final cards = {
      'b': reviewCard('b', now.subtract(const Duration(days: 1)), 2),
      'c': reviewCard('c', now, 1),
      'd': reviewCard('d', now.add(const Duration(days: 3)), 3),
      'f': SrsCard(
        itemKey: 'f',
        state: SrsState.learning,
        dueAt: now.add(const Duration(minutes: 10)),
        intervalDays: 0,
      ),
    };

    final plan = SrsScheduler.planToday(
      catalogOrder: catalog,
      cards: cards,
      now: now,
      groupKeys: ['e', 'f', 'g'],
    );
    expect(plan.dueKeys, ['b', 'c']);
    expect(plan.newKeys, ['e', 'g']);
    expect(plan.itemKeys, ['b', 'c', 'e', 'g']);
    expect(plan.itemKeys.contains('a'), isFalse);
    expect(plan.itemKeys.contains('d'), isFalse);
    expect(plan.itemKeys.contains('f'), isFalse);

    final noGroup = SrsScheduler.planToday(
      catalogOrder: catalog,
      cards: cards,
      now: now,
    );
    expect(noGroup.newKeys, isEmpty);
    expect(noGroup.itemKeys, ['b', 'c']);
  });

  test('模块队列只含该模块，到期和学习中的在前', () {
    final keys = [
      for (final item in KnowledgeCatalog.itemsForModule('tiangandizhi_wuxing'))
        item.itemKey,
    ];
    expect(keys, isNotEmpty);
    expect(
      keys.every(
        (key) =>
            key.startsWith('gan_wuxing:') || key.startsWith('zhi_wuxing:'),
      ),
      isTrue,
    );

    final cards = {
      keys[2]: reviewCard(keys[2], now.subtract(const Duration(days: 1)), 3),
      keys[0]: SrsCard(
        itemKey: keys[0],
        state: SrsState.learning,
        dueAt: now.add(const Duration(minutes: 10)),
        intervalDays: 0,
      ),
      keys[1]: reviewCard(keys[1], now.add(const Duration(days: 2)), 2),
      'gan_yinyang:甲': reviewCard(
        'gan_yinyang:甲',
        now.subtract(const Duration(hours: 1)),
        1,
      ),
    };
    final queue = SrsScheduler.moduleQueue(
      moduleItemKeys: keys,
      cards: cards,
      now: now,
    );
    final unseen = [
      for (final key in keys)
        if (key != keys[0] && key != keys[1] && key != keys[2]) key,
    ];
    expect(queue.contains('gan_yinyang:甲'), isFalse);
    expect(queue.toSet(), keys.toSet());
    expect(queue, [keys[2], keys[0], keys[1], ...unseen]);
  });

  test('没有到期时模块队列仍可巩固，且不含其他模块', () {
    final now = DateTime(2026, 10, 15);
    final queue = SrsScheduler.moduleQueue(
      moduleItemKeys: const ['a', 'b', 'c'],
      cards: {
        'b': reviewCard('b', now.add(const Duration(days: 4)), 4),
        'other': SrsCard(
          itemKey: 'other',
          state: SrsState.learning,
          dueAt: now,
          intervalDays: 0,
        ),
      },
      now: now,
    );
    expect(queue, ['b', 'a', 'c']);

    final guaKeys = [
      for (final item in KnowledgeCatalog.itemsForModule('64gua')) item.itemKey,
    ];
    expect(guaKeys, isNotEmpty);
    expect(
      guaKeys.every(
        (key) =>
            key.startsWith('gua_to_xiang:') || key.startsWith('xiang_to_gua:'),
      ),
      isTrue,
    );
    expect(
      SrsScheduler.moduleQueue(
        moduleItemKeys: guaKeys,
        cards: const {},
        now: now,
      ),
      guaKeys,
    );
  });

  test('分数映射到 1 至 7 天，满 21 天算已掌握', () {
    expect(SrsScheduler.intervalDaysForScore(60), 1);
    expect(SrsScheduler.intervalDaysForScore(100), 7);
    expect(
      SrsScheduler.isMastered(reviewCard('a', now, 21)),
      isTrue,
    );
    expect(
      SrsScheduler.isMastered(reviewCard('a', now, 20)),
      isFalse,
    );
    expect(
      SrsScheduler.isMastered(
        SrsCard(
          itemKey: 'a',
          state: SrsState.learning,
          dueAt: now,
          intervalDays: 30,
        ),
      ),
      isFalse,
    );
  });

  group('连续学习天数', () {
    SrsCard reviewedAt(String itemKey, DateTime? at) {
      return SrsCard(
        itemKey: itemKey,
        state: SrsState.review,
        dueAt: now,
        intervalDays: 1,
        lastReviewedAt: at,
      );
    }

    test('没有复习记录是 0', () {
      expect(SrsScheduler.studyStreakDays(const [], now), 0);
      expect(SrsScheduler.studyStreakDays([reviewedAt('a', null)], now), 0);
    });

    test('从今天往前数连续有复习的日子，中间断一天就停', () {
      final cards = [
        reviewedAt('a', DateTime(2026, 10, 15, 7)),
        reviewedAt('b', DateTime(2026, 10, 14, 23, 50)),
        reviewedAt('c', DateTime(2026, 10, 13, 0, 5)),
        reviewedAt('d', DateTime(2026, 10, 13, 12)),
        reviewedAt('e', DateTime(2026, 10, 11, 12)),
      ];
      expect(SrsScheduler.studyStreakDays(cards, now), 3);
    });

    test('今天还没复习时从昨天算起', () {
      final cards = [
        reviewedAt('a', DateTime(2026, 10, 14, 20)),
        reviewedAt('b', DateTime(2026, 10, 13, 20)),
      ];
      expect(SrsScheduler.studyStreakDays(cards, now), 2);
    });

    test('最近一次复习在前天就算断了', () {
      final cards = [reviewedAt('a', DateTime(2026, 10, 13, 20))];
      expect(SrsScheduler.studyStreakDays(cards, now), 0);
    });

    test('跨月按日历日连续', () {
      final cards = [
        reviewedAt('a', DateTime(2026, 11, 1, 8)),
        reviewedAt('b', DateTime(2026, 10, 31, 8)),
      ];
      expect(SrsScheduler.studyStreakDays(cards, DateTime(2026, 11, 1, 9)), 2);
    });
  });
}
