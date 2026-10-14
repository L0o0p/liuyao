const Map<String, String> liuHe = {
  "子": "丑",
  "寅": "亥",
  "卯": "戌",
  "辰": "酉",
  "巳": "申",
  "午": "未",
};

const List<List<String>> sanHe = [
  ["申", "子", "辰"], // 水三合
  ["亥", "卯", "未"], // 木三合
  ["寅", "午", "戌"], // 火三合
  ["巳", "酉", "丑"], // 金三合
];

const List<List<String>> sanXing = [
  ["寅", "巳", "申"], // 寅巳申三刑（无恩之刑）
  ["丑", "戌", "未"], // 丑戌未三刑（持势之刑）
  ["子", "卯"], // 子卯相刑（无礼之刑）
];

const Map<String, String> ziXing = {"辰": "辰", "午": "午", "酉": "酉", "亥": "亥"};

// 十二长生
const List<String> changShengCycle = [
  "长生",
  "沐浴",
  "冠带",
  "临官",
  "帝旺",
  "衰",
  "病",
  "死",
  "墓",
  "绝",
  "胎",
  "养",
];

// 五行起点：表示某五行的“长生”落在哪个日支上
const Map<String, String> wuXingChangShengStart = {
  "木": "亥",
  "火": "寅",
  "金": "巳",
  "水": "申",
  "土": "申", // 水土共起同位置
};

// 地支 → 五行
const Map<String, String> zhiWuXing = {
  "寅": "木",
  "卯": "木",
  "巳": "火",
  "午": "火",
  "申": "金",
  "酉": "金",
  "亥": "水",
  "子": "水",
  "辰": "土",
  "戌": "土",
  "丑": "土",
  "未": "土",
};

// 十二地支循环
const List<String> diZhiCycle = [
  "子",
  "丑",
  "寅",
  "卯",
  "辰",
  "巳",
  "午",
  "未",
  "申",
  "酉",
  "戌",
  "亥",
];

/// 六冲：地支循环上相隔六位。
String liuChongOf(String zhi) {
  final index = diZhiCycle.indexOf(zhi);
  if (index < 0) return "未知";
  return diZhiCycle[(index + 6) % diZhiCycle.length];
}

/// 六害。
const Map<String, String> liuHai = {
  "子": "未",
  "丑": "午",
  "寅": "巳",
  "卯": "辰",
  "辰": "卯",
  "巳": "寅",
  "午": "丑",
  "未": "子",
  "申": "亥",
  "酉": "戌",
  "戌": "酉",
  "亥": "申",
};

/// 相破。
const Map<String, String> poXiang = {
  "子": "酉",
  "丑": "辰",
  "寅": "亥",
  "卯": "午",
  "辰": "丑",
  "巳": "申",
  "午": "卯",
  "未": "戌",
  "申": "巳",
  "酉": "子",
  "戌": "未",
  "亥": "寅",
};
