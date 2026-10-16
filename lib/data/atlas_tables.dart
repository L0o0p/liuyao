import 'di_zhi.dart';
import 'gua_data.dart';
import 'tian_gan.dart';
import 'wu_xing.dart';
import 'zhi_relations.dart';

class AtlasTable {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;

  const AtlasTable({
    required this.title,
    required this.columns,
    required this.rows,
  });
}

class AtlasChapter {
  final String title;
  final String summary;
  final List<AtlasTable> tables;

  const AtlasChapter({
    required this.title,
    required this.summary,
    required this.tables,
  });
}

/// 按学习顺序排列。
List<AtlasChapter> buildAtlasChapters() {
  return [
    wuXingAtlas(),
    tianGanAtlas(),
    diZhiAtlas(),
    xingChongHeHaiAtlas(),
    changShengAtlas(),
    guaAtlas(),
  ];
}

AtlasChapter wuXingAtlas() {
  return AtlasChapter(
    title: '五行生克',
    summary: '木生火，火生土，土生金，金生水，水生木。木克土，土克水，水克火，火克金，金克木。',
    tables: [
      AtlasTable(
        title: '生与克',
        columns: ['五行', '所生', '所克'],
        rows: [
          for (final name in wuXingSheng.keys)
            [name, wuXingSheng[name]!, wuXingKe[name]!],
        ],
      ),
    ],
  );
}

AtlasChapter tianGanAtlas() {
  return AtlasChapter(
    title: '天干',
    summary: '甲乙东方木，丙丁南方火，戊己中央土，庚辛西方金，壬癸北方水。',
    tables: [
      AtlasTable(
        title: '天干属性',
        columns: ['天干', '阴阳', '五行', '方位', '季节', '月份', '时辰'],
        rows: [
          for (final row in tianGan)
            [
              row['name']!,
              row['yinYang']!,
              row['wuXing']!,
              row['direction']!,
              row['season']!,
              row['month']!,
              row['time']!,
            ],
        ],
      ),
    ],
  );
}

AtlasChapter diZhiAtlas() {
  return AtlasChapter(
    title: '地支',
    summary: '寅卯木，巳午火，申酉金，亥子水，辰戌丑未土。子起阳阴相间，每支固定在一个指节上。',
    tables: [
      AtlasTable(
        title: '地支属性',
        columns: ['地支', '阴阳', '五行', '方位', '季节', '月份', '时辰', '钟点'],
        rows: [
          for (final row in diZhi)
            [
              row['name']!,
              row['yinYang']!,
              row['wuXing']!,
              row['direction']!,
              row['season']!,
              row['month']!,
              row['time']!,
              row['hour']!,
            ],
        ],
      ),
      AtlasTable(
        title: '十二支指诀',
        columns: ['地支', '指节'],
        rows: [
          for (final row in diZhi) [row['name']!, row['fingerJoint']!],
        ],
      ),
    ],
  );
}

AtlasChapter xingChongHeHaiAtlas() {
  return AtlasChapter(
    title: '刑冲合害',
    summary: '六合六对，三合四局，另有三刑、自刑、六冲、六害、相破。',
    tables: [
      AtlasTable(
        title: '六合',
        columns: ['地支', '相合'],
        rows: [
          for (final entry in liuHe.entries) [entry.key, entry.value],
        ],
      ),
      const AtlasTable(
        title: '三合',
        columns: ['组合', '局'],
        rows: [
          ['申 子 辰', '水'],
          ['亥 卯 未', '木'],
          ['寅 午 戌', '火'],
          ['巳 酉 丑', '金'],
        ],
      ),
      const AtlasTable(
        title: '三刑',
        columns: ['组合', '名称'],
        rows: [
          ['寅 巳 申', '无恩之刑'],
          ['丑 戌 未', '持势之刑'],
          ['子 卯', '无礼之刑'],
        ],
      ),
      AtlasTable(
        title: '自刑',
        columns: ['地支'],
        rows: [
          for (final zhi in ziXing.keys) [zhi],
        ],
      ),
      AtlasTable(
        title: '六冲',
        columns: ['地支', '相冲'],
        rows: [
          for (final zhi in diZhiCycle) [zhi, liuChongOf(zhi)],
        ],
      ),
      AtlasTable(
        title: '六害',
        columns: ['地支', '相害'],
        rows: [
          for (final entry in liuHai.entries) [entry.key, entry.value],
        ],
      ),
      AtlasTable(
        title: '相破',
        columns: ['地支', '相破'],
        rows: [
          for (final entry in poXiang.entries) [entry.key, entry.value],
        ],
      ),
    ],
  );
}

AtlasChapter changShengAtlas() {
  return AtlasChapter(
    title: '十二长生',
    summary: '看日支的五行，从该五行的长生起点沿地支顺数到爻支。',
    tables: [
      AtlasTable(
        title: '阶段顺序',
        columns: ['次序', '阶段'],
        rows: [
          for (var i = 0; i < changShengCycle.length; i++)
            ['${i + 1}', changShengCycle[i]],
        ],
      ),
      AtlasTable(
        title: '长生起点',
        columns: ['五行', '长生所在'],
        rows: [
          for (final entry in wuXingChangShengStart.entries)
            [entry.key, entry.value],
        ],
      ),
    ],
  );
}

AtlasChapter guaAtlas() {
  return AtlasChapter(
    title: '六十四卦',
    summary: '卦象两个字，前一个是上卦，后一个是下卦。',
    tables: [
      AtlasTable(
        title: '卦名与卦象',
        columns: ['卦名', '卦象', '符号'],
        rows: [
          for (final entry in guaMap.entries)
            [entry.key, entry.value, getGuaSymbol(entry.value)],
        ],
      ),
    ],
  );
}
