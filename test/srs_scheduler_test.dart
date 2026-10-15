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

  test('答错把间隔缩到 10 分钟，再答对时按学习卡毕业', () {
    final card = reviewCard('gan_wuxing:甲', now.add(const Duration(days: 4)), 4);
    final wrong = SrsScheduler.grade(
      card: card,
      correct: false,
      elapsed: const Duration(seconds: 3),
      now: now,
    );

    expect(wrong.state, SrsState.learning);
    expect(wrong.intervalDays, 0);
    expect(wrong.lapses, 1);
    expect(wrong.reps, 3);
    expect(wrong.lastReviewedAt, now);
    expect(wrong.dueAt, now.add(const Duration(minutes: 10)));
    expect(wrong.dueAt.isBefore(card.dueAt), isTrue);

    final recovered = SrsScheduler.grade(
      card: wrong,
      correct: true,
      elapsed: const Duration(seconds: 3),
      now: now,
    );
    expect(recovered.state, SrsState.review);
    expect(recovered.intervalDays, 1);
    expect(recovered.dueAt, now.add(const Duration(days: 1)));
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

  test('今日队列先到期再新学，且新学不超过 5', () {
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
      introducedToday: 0,
      now: now,
    );
    expect(plan.dueKeys, ['b', 'c']);
    expect(plan.newKeys, ['a', 'e', 'g', 'h']);
    expect(plan.itemKeys, ['b', 'c', 'a', 'e', 'g', 'h']);
    expect(plan.newCount, lessThanOrEqualTo(5));
    expect(plan.itemKeys.contains('d'), isFalse);
    expect(plan.itemKeys.contains('f'), isFalse);

    final limited = SrsScheduler.planToday(
      catalogOrder: catalog,
      cards: cards,
      introducedToday: 4,
      now: now,
    );
    expect(limited.newKeys, ['a']);
    expect(limited.itemKeys.first, 'b');

    final full = SrsScheduler.planToday(
      catalogOrder: catalog,
      cards: cards,
      introducedToday: 5,
      now: now,
    );
    expect(full.newKeys, isEmpty);
    expect(full.itemKeys, ['b', 'c']);
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
}
