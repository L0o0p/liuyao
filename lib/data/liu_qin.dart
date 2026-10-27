import 'shi_ying.dart';
import 'wu_xing.dart';
import 'zhi_relations.dart';

/// 六亲。以卦宫五行为「我」。
const List<String> liuQinNames = ['父母', '兄弟', '子孙', '妻财', '官鬼'];

/// 八宫五行：乾兑金，坤艮土，震巽木，坎水，离火。
const Map<String, String> palaceWuXing = {
  '乾': '金',
  '坤': '土',
  '震': '木',
  '巽': '木',
  '坎': '水',
  '离': '火',
  '艮': '土',
  '兑': '金',
};

/// 生出 [element] 的五行。
String generatorOf(String element) {
  return wuXingSheng.entries.firstWhere((entry) => entry.value == element).key;
}

/// 克 [element] 的五行。
String overcomeBy(String element) {
  return wuXingKe.entries.firstWhere((entry) => entry.value == element).key;
}

List<String> zhiOfWuXing(String element) {
  return [
    for (final zhi in diZhiCycle)
      if (zhiWuXing[zhi] == element) zhi,
  ];
}

/// 爻五行相对宫五行的六亲。配不上五行时返回 null。
String? liuQinOf(String gongWuXing, String yaoWuXing) {
  if (!wuXingSheng.containsKey(gongWuXing) ||
      !wuXingSheng.containsKey(yaoWuXing)) {
    return null;
  }
  if (gongWuXing == yaoWuXing) return '兄弟';
  if (wuXingSheng[gongWuXing] == yaoWuXing) return '子孙';
  if (wuXingSheng[yaoWuXing] == gongWuXing) return '父母';
  if (wuXingKe[gongWuXing] == yaoWuXing) return '妻财';
  if (wuXingKe[yaoWuXing] == gongWuXing) return '官鬼';
  return null;
}

/// 给定宫五行和六亲，爻五行是唯一的。
String yaoWuXingForLiuQin(String gongWuXing, String liuQin) {
  switch (liuQin) {
    case '兄弟':
      return gongWuXing;
    case '子孙':
      return wuXingSheng[gongWuXing]!;
    case '父母':
      return generatorOf(gongWuXing);
    case '妻财':
      return wuXingKe[gongWuXing]!;
    case '官鬼':
      return overcomeBy(gongWuXing);
    default:
      throw ArgumentError('未知六亲: $liuQin');
  }
}

String? liuQinOfGua(String guaName, String yaoZhi) {
  final palace = palaceOf(guaName);
  final gongWuXing = palace == null ? null : palaceWuXing[palace];
  final yaoWuXing = zhiWuXing[yaoZhi];
  if (gongWuXing == null || yaoWuXing == null) return null;
  return liuQinOf(gongWuXing, yaoWuXing);
}

/// 宫五行对爻五行的那一句关系，最后落到六亲。
List<String> liuQinSteps(String guaName, String yaoZhi) {
  final palace = palaceOf(guaName);
  final gongWuXing = palace == null ? null : palaceWuXing[palace];
  final yaoWuXing = zhiWuXing[yaoZhi];
  final liuQin = gongWuXing == null || yaoWuXing == null
      ? null
      : liuQinOf(gongWuXing, yaoWuXing);
  if (palace == null ||
      gongWuXing == null ||
      yaoWuXing == null ||
      liuQin == null) {
    return const [];
  }
  final String relation;
  if (gongWuXing == yaoWuXing) {
    relation = '$gongWuXing与$yaoWuXing比和，比和者为兄弟';
  } else if (wuXingSheng[gongWuXing] == yaoWuXing) {
    relation = '$gongWuXing生$yaoWuXing，我生者为子孙';
  } else if (wuXingSheng[yaoWuXing] == gongWuXing) {
    relation = '$yaoWuXing生$gongWuXing，生我者为父母';
  } else if (wuXingKe[gongWuXing] == yaoWuXing) {
    relation = '$gongWuXing克$yaoWuXing，我克者为妻财';
  } else {
    relation = '$yaoWuXing克$gongWuXing，克我者为官鬼';
  }
  return [
    '${guaTitle(guaName)}属$palace宫，宫五行$gongWuXing',
    '爻支$yaoZhi属$yaoWuXing',
    relation,
    liuQin,
  ];
}

/// 能排出指定六亲的卦。用来抽题。
List<String> guasForPalaceElement(String gongWuXing) {
  return [
    for (final palace in palaceNames)
      if (palaceWuXing[palace] == gongWuXing) ...guasInPalace(palace),
  ];
}
