import '../data/tian_gan.dart';

String getGanWuXing(String gan) {
  final match = tianGan.firstWhere((g) => g["name"] == gan, orElse: () => {});
  return match["wuXing"] ?? "未知";
}
