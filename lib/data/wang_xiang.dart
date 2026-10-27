import 'liu_qin.dart';
import 'wu_xing.dart';
import 'zhi_relations.dart';

/// 月令相对爻五行的旺相休囚死。月令是「我」。
const List<String> wangXiangNames = ['旺', '相', '休', '囚', '死'];

/// 月支、爻支都是地支。配不上时返回 null。
String? wangXiangOf(String monthZhi, String yaoZhi) {
  final month = zhiWuXing[monthZhi];
  final yao = zhiWuXing[yaoZhi];
  if (month == null || yao == null) return null;
  if (month == yao) return '旺';
  if (wuXingSheng[month] == yao) return '相';
  if (wuXingSheng[yao] == month) return '休';
  if (wuXingKe[yao] == month) return '囚';
  if (wuXingKe[month] == yao) return '死';
  return null;
}

/// 给定月令五行和状态，爻五行是唯一的。
String yaoWuXingForWangXiang(String monthWuXing, String state) {
  switch (state) {
    case '旺':
      return monthWuXing;
    case '相':
      return wuXingSheng[monthWuXing]!;
    case '休':
      return generatorOf(monthWuXing);
    case '囚':
      return overcomeBy(monthWuXing);
    case '死':
      return wuXingKe[monthWuXing]!;
    default:
      throw ArgumentError('未知旺相: $state');
  }
}

List<String> wangXiangSteps(String monthZhi, String yaoZhi) {
  final month = zhiWuXing[monthZhi];
  final yao = zhiWuXing[yaoZhi];
  final state = wangXiangOf(monthZhi, yaoZhi);
  if (month == null || yao == null || state == null) return const [];
  final String relation;
  if (month == yao) {
    relation = '$yao与月令$month同五行，为旺';
  } else if (wuXingSheng[month] == yao) {
    relation = '$month生$yao，月令所生为相';
  } else if (wuXingSheng[yao] == month) {
    relation = '$yao生$month，生月令者为休';
  } else if (wuXingKe[yao] == month) {
    relation = '$yao克$month，克月令者为囚';
  } else {
    relation = '$month克$yao，月令所克为死';
  }
  return ['月支$monthZhi属$month', '爻支$yaoZhi属$yao', relation, state];
}
