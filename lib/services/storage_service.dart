import '../data/knowledge_catalog.dart';
import '../models/srs_card.dart';
import 'local_store.dart';

/// 复习卡片存在 LocalStore 的 `srs:{itemKey}` 上。
/// 当天新学计数单独放在 [LocalStore.srsDailyKey]，不进同步集合。
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
    for (final item in KnowledgeCatalog.itemsForModule(moduleId)) {
      final existing = await LocalStore.instance.get(cardKey(item.itemKey));
      if (existing == null || LocalStore.isDeleted(existing)) continue;
      await deleteCard(item.itemKey);
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

  static Future<int> introducedOn(DateTime now) async {
    final data = await LocalStore.instance.get(LocalStore.srsDailyKey);
    if (data == null || data['date'] != dayStamp(now)) return 0;
    final raw = data['introduced'];
    if (raw is int) return raw < 0 ? 0 : raw;
    if (raw is num) {
      final value = raw.toInt();
      return value < 0 ? 0 : value;
    }
    return 0;
  }

  static Future<void> addIntroduced(DateTime now, int count) async {
    if (count <= 0) return;
    final current = await introducedOn(now);
    await LocalStore.instance.writePlain(LocalStore.srsDailyKey, {
      'date': dayStamp(now),
      'introduced': current + count,
    });
  }
}
