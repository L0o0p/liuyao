import 'package:liuyao/data/di_zhi.dart';
import 'package:liuyao/data/zhi_relations.dart';

import '../data/tian_gan.dart';

String getGanWuXing(String gan) {
  final match = tianGan.firstWhere((g) => g["name"] == gan, orElse: () => {});
  return match["wuXing"] ?? "未知";
}

String getGanYinYang(String gan) {
  final match = tianGan.firstWhere((g) => g["name"] == gan, orElse: () => {});
  return match["yinYang"] ?? "未知";
}

String getZhiYinYang(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["yinYang"] ?? "未知";
}

String getZhiWuXing(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["wuXing"] ?? "未知";
}

String getLiuHe(String zhi) {
  return liuHe[zhi] ?? "无六合";
}

List<String> getSanHe(String zhi) {
  return sanHe.firstWhere((group) => group.contains(zhi), orElse: () => []);
}

String getWuXingChangSheng(String riZhi, String yaoZhi) {
  // 找出该爻地支的五行
  final wuXing = zhiWuXing[yaoZhi] ?? "未知";
  if (wuXing == "未知") return "未知";

  // 找这个五行对应的长生起点日支
  final startZhi = wuXingChangShengStart[wuXing]!;
  // 起点索引
  final startIndex = diZhiCycle.indexOf(startZhi);
  final yaoIndex = diZhiCycle.indexOf(yaoZhi);

  if (yaoIndex < 0 || startIndex < 0) return "未知";

  // 计算爻支相对于长生起点的位置
  // 从长生起点开始，按地支顺序计算爻支是第几个位置
  int offset = (yaoIndex - startIndex) % 12;
  if (offset < 0) offset += 12; // 转正

  return changShengCycle[offset];
}

// 天干方位相关函数
String getGanDirection(String gan) {
  final match = tianGan.firstWhere((g) => g["name"] == gan, orElse: () => {});
  return match["direction"] ?? "未知";
}

String getGanSeason(String gan) {
  final match = tianGan.firstWhere((g) => g["name"] == gan, orElse: () => {});
  return match["season"] ?? "未知";
}

String getGanMonth(String gan) {
  final match = tianGan.firstWhere((g) => g["name"] == gan, orElse: () => {});
  return match["month"] ?? "未知";
}

String getGanTime(String gan) {
  final match = tianGan.firstWhere((g) => g["name"] == gan, orElse: () => {});
  return match["time"] ?? "未知";
}

// 地支方位时间相关函数
String getZhiDirection(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["direction"] ?? "未知";
}

String getZhiSeason(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["season"] ?? "未知";
}

String getZhiMonth(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["month"] ?? "未知";
}

String getZhiTime(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["time"] ?? "未知";
}

String getZhiHour(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["hour"] ?? "未知";
}

// 地支指节相关函数
String getZhiFingerJoint(String zhi) {
  final match = diZhi.firstWhere((g) => g["name"] == zhi, orElse: () => {});
  return match["fingerJoint"] ?? "未知";
}

// 从指节查找对应的地支
String getFingerJointZhi(String fingerJoint) {
  final match = diZhi.firstWhere(
    (g) => g["fingerJoint"] == fingerJoint,
    orElse: () => {},
  );
  return match["name"] ?? "未知";
}
