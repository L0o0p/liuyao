import 'gua_data.dart';

/// 八宫里的世次，顺序与 [guaMap] 每一宫的八卦一致。
const List<String> shiCiNames = [
  '本宫',
  '一世',
  '二世',
  '三世',
  '四世',
  '五世',
  '游魂',
  '归魂',
];

/// 世爻下标：初爻 0，上爻 5。游魂同四世，归魂同三世。
const List<int> shiYaoIndex = [5, 0, 1, 2, 3, 4, 3, 2];

const List<String> yaoPositionNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

const List<String> palaceNames = ['乾', '坤', '震', '巽', '坎', '离', '艮', '兑'];

const Map<String, String> pureGuaTitles = {
  '乾': '乾为天',
  '坤': '坤为地',
  '震': '震为雷',
  '巽': '巽为风',
  '坎': '坎为水',
  '离': '离为火',
  '艮': '艮为山',
  '兑': '兑为泽',
};

/// 题面上的卦名。八纯卦用「乾为天」，其余用卦象加卦名，如「天风姤」。
String guaTitle(String name) {
  final pure = pureGuaTitles[name];
  if (pure != null) return pure;
  final xiang = getGuaXiang(name);
  if (xiang == null) return name;
  return '$xiang$name';
}

/// 卦所在的宫。乾宫到兑宫与 [guaMap] 的八宫顺序一致。
String? palaceOf(String guaName) {
  final index = getAllGuaNames().indexOf(guaName);
  if (index < 0) return null;
  return palaceNames[index ~/ shiCiNames.length];
}

/// 某一宫里的八卦，顺序是本宫到归魂。
List<String> guasInPalace(String palace) {
  final palaceIndex = palaceNames.indexOf(palace);
  if (palaceIndex < 0) return const [];
  final names = getAllGuaNames();
  final start = palaceIndex * shiCiNames.length;
  return names.sublist(start, start + shiCiNames.length);
}

/// 卦在本宫中的世次，0 是本宫，6 是游魂，7 是归魂。
int? generationOf(String guaName) {
  final index = getAllGuaNames().indexOf(guaName);
  if (index < 0) return null;
  return index % shiCiNames.length;
}

String shiYingAnswerFor(int generation) {
  final shi = shiYaoIndex[generation];
  final ying = (shi + 3) % yaoPositionNames.length;
  return '世${yaoPositionNames[shi]}，应${yaoPositionNames[ying]}';
}

String? shiYingOf(String guaName) {
  final generation = generationOf(guaName);
  if (generation == null) return null;
  return shiYingAnswerFor(generation);
}

/// 某个世次在八宫里各有一卦。
List<String> guasInGeneration(String shiCi) {
  final generation = shiCiNames.indexOf(shiCi);
  if (generation < 0) return const [];
  final names = getAllGuaNames();
  return [
    for (var palace = 0; palace < palaceNames.length; palace++)
      names[palace * shiCiNames.length + generation],
  ];
}

/// 六种不同的世应答案。四世与游魂相同，三世与归魂相同。
List<String> shiYingPairs() {
  final seen = <String>{};
  return [
    for (var i = 0; i < shiCiNames.length; i++)
      if (seen.add(shiYingAnswerFor(i))) shiYingAnswerFor(i),
  ];
}

/// 先定位宫和世次，再按世次取世爻，应爻隔两位。
List<String> shiYingSteps(String guaName) {
  final names = getAllGuaNames();
  final index = names.indexOf(guaName);
  final generation = generationOf(guaName);
  if (index < 0 || generation == null) return const [];
  final palaceIndex = index ~/ shiCiNames.length;
  final palace = palaceNames[palaceIndex];
  final mates = names.sublist(
    palaceIndex * shiCiNames.length,
    palaceIndex * shiCiNames.length + shiCiNames.length,
  );
  final shi = shiYaoIndex[generation];
  final ying = (shi + 3) % yaoPositionNames.length;
  final ci = shiCiNames[generation];
  return [
    '${guaTitle(guaName)}是$palace宫$ci卦',
    '$palace宫依次是${mates.join('、')}，$guaName排第${generation + 1}位',
    '$ci卦世在${yaoPositionNames[shi]}，应在${yaoPositionNames[ying]}',
    shiYingAnswerFor(generation),
  ];
}
