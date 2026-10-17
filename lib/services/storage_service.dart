import '../data/knowledge_catalog.dart';
import '../models/srs_card.dart';
import 'local_store.dart';

/// 复习卡片存在 LocalStore 的 `srs:{itemKey}` 上。
/// 当天引入过哪些小组单独放在 [LocalStore.srsDailyKey]，不进同步集合，也不导出：
/// 它只决定今天还要不要自动引入新组，换机后丢了最多让当天多引入一组。
class StorageService {
  static Future<void> initialize() async {
    await LocalStore.instance.migrateIfNeeded();
  }

  static String cardKey(String itemKey) => '${LocalStore.srsPrefix}$itemKey';

  static Future<Map<String, SrsCard>> loadCards() async {
    final keys = await LocalStore.instance.keysWithPrefix(LocalStore.srsPrefix);
    final cards = <String, SrsCard>{};
    for (final key in keys) {
      final data = await LocalStore.instance.get(key);
      if (data == null || LocalStore.isDeleted(data)) continue;
      final itemKey = key.substring(LocalStore.srsPrefix.length);
      if (itemKey.isEmpty) continue;
      try {
        final card = SrsCard.fromJson(data, fallbackItemKey: itemKey);
        if (card.itemKey.isEmpty) continue;
        cards[card.itemKey] = card;
      } catch (_) {
        continue;
      }
    }
    return cards;
  }

  static Future<SrsCard?> loadCard(String itemKey) async {
    final data = await LocalStore.instance.get(cardKey(itemKey));
    if (data == null || LocalStore.isDeleted(data)) return null;
    try {
      return SrsCard.fromJson(data, fallbackItemKey: itemKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCard(SrsCard card) async {
    final stamped = card.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await LocalStore.instance.put(cardKey(card.itemKey), stamped.toJson());
  }

  static Future<void> deleteCard(String itemKey) async {
    await LocalStore.instance.delete(cardKey(itemKey));
  }

  static Future<void> clearModule(String moduleId) async {
    await clearItems(
      KnowledgeCatalog.itemsForModule(moduleId).map((item) => item.itemKey),
    );
  }

  static Future<void> clearItems(Iterable<String> itemKeys) async {
    for (final itemKey in itemKeys) {
      final existing = await LocalStore.instance.get(cardKey(itemKey));
      if (existing == null || LocalStore.isDeleted(existing)) continue;
      await deleteCard(itemKey);
    }
  }

  static Future<void> clearAllCards() async {
    final keys = await LocalStore.instance.keysWithPrefix(LocalStore.srsPrefix);
    for (final key in keys) {
      final existing = await LocalStore.instance.get(key);
      if (existing == null || LocalStore.isDeleted(existing)) continue;
      await LocalStore.instance.delete(key);
    }
  }

  static String dayStamp(DateTime time) {
    final local = time.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 当天已经引入过的小组 id。旧版本存的是条数，没有 groups 字段，按没引入过算。
  static Future<List<String>> groupsIntroducedOn(DateTime now) async {
    final data = await LocalStore.instance.get(LocalStore.srsDailyKey);
    if (data == null || data['date'] != dayStamp(now)) return const [];
    final raw = data['groups'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  static Future<void> markGroupIntroduced(DateTime now, String groupId) async {
    final current = await groupsIntroducedOn(now);
    if (current.contains(groupId)) return;
    await LocalStore.instance.writePlain(LocalStore.srsDailyKey, {
      'date': dayStamp(now),
      'groups': [...current, groupId],
    });
  }
}
