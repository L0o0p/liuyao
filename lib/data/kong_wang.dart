import 'tian_gan.dart';
import 'zhi_relations.dart';

/// 日柱。天干、地支同阴或同阳才是合法的六十甲子。
class RiZhu {
  final String gan;
  final String zhi;

  const RiZhu(this.gan, this.zhi);

  String get text => '$gan$zhi';
}

final List<String> tianGanCycle = [for (final item in tianGan) item['name']!];

/// 六旬的旬首地支：甲子、甲戌、甲申、甲午、甲辰、甲寅。
/// 每一旬十个日柱，下一旬的旬首在地支上倒退两位。
final List<String> xunHeadBranches = [
  for (var i = 0; i < 6; i++) diZhiCycle[(12 - 2 * i) % 12],
];

int _mod(int value, int length) => (value % length + length) % length;

/// 日柱所在旬的旬首地支。配不成六十甲子时返回 null。
String? xunHeadOf(String gan, String zhi) {
  final ganIndex = tianGanCycle.indexOf(gan);
  final zhiIndex = diZhiCycle.indexOf(zhi);
  if (ganIndex < 0 || zhiIndex < 0) return null;
  if ((zhiIndex - ganIndex).isOdd) return null;
  return diZhiCycle[_mod(zhiIndex - ganIndex, 12)];
}

/// 空亡的两个地支，按地支顺序连写，例如戊戌日得到「辰巳」。
/// 旬首再往回数两位：先数到的写在后面。
String? kongWangOf(String gan, String zhi) {
  final head = xunHeadOf(gan, zhi);
  if (head == null) return null;
  final headIndex = diZhiCycle.indexOf(head);
  final farther = diZhiCycle[_mod(headIndex - 2, 12)];
  final nearer = diZhiCycle[_mod(headIndex - 1, 12)];
  return '$farther$nearer';
}

/// 六对空亡，顺序与 [xunHeadBranches] 一致。
List<String> kongWangPairs() => [
  for (final head in xunHeadBranches) kongWangOf('甲', head)!,
];

/// [xun] 写成「甲午」这种旬首干支，不含「旬」。
List<RiZhu> daysInXun(String xun) {
  if (!xun.startsWith('甲') || xun.length != 2) return const [];
  final headIndex = diZhiCycle.indexOf(xun[1]);
  if (headIndex < 0 || !xunHeadBranches.contains(xun[1])) return const [];
  return [
    for (var i = 0; i < tianGanCycle.length; i++)
      RiZhu(tianGanCycle[i], diZhiCycle[_mod(headIndex + i, 12)]),
  ];
}

/// 学员用的算法：日干倒着数到甲，日支退同样的位数得到旬首，再往回数两位。
/// 例如戊戌日：戊退 4 位到甲，戌退到午，午再往回数到辰巳。
List<String> kongWangSteps(String gan, String zhi) {
  final ganIndex = tianGanCycle.indexOf(gan);
  final zhiIndex = diZhiCycle.indexOf(zhi);
  final head = xunHeadOf(gan, zhi);
  final pair = kongWangOf(gan, zhi);
  if (ganIndex < 0 || zhiIndex < 0 || head == null || pair == null) {
    return const [];
  }
  final headIndex = diZhiCycle.indexOf(head);
  final nearer = diZhiCycle[_mod(headIndex - 1, 12)];
  final farther = diZhiCycle[_mod(headIndex - 2, 12)];
  final counted = '从$head往回数两位：$head、$nearer、$farther，空亡$pair';
  if (ganIndex == 0) {
    return ['日干是甲，旬首就是甲$head', counted];
  }
  final ganWalk = [
    for (var i = 0; i <= ganIndex; i++) tianGanCycle[ganIndex - i],
  ];
  final zhiWalk = [
    for (var i = 0; i <= ganIndex; i++) diZhiCycle[_mod(zhiIndex - i, 12)],
  ];
  return [
    '从$gan倒着数到甲：${ganWalk.join('、')}，退$ganIndex位',
    '从$zhi退$ganIndex位：${zhiWalk.join('、')}，旬首是甲$head',
    counted,
  ];
}
