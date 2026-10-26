import '../models/question.dart';
import 'di_zhi.dart';
import 'gua_data.dart';
import 'knowledge_catalog.dart';
import 'kong_wang.dart';
import 'tian_gan.dart';
import 'wu_xing.dart';
import 'zhi_relations.dart';

/// 答题前和答错后给用户看的说明。结论必须包含题目的正确答案。
class TeachingNote {
  final String title;
  final String fact;
  final String hint;

  const TeachingNote({
    required this.title,
    required this.hint,
    required this.fact,
  });
}

class TeachingNotes {
  static TeachingNote forItem(KnowledgeItem item) {
    switch (item.questionType) {
      case 'gan_wuxing':
      case 'gan_direction':
      case 'gan_season':
        return TeachingNote(
          title: KnowledgeCatalog.questionTypeLabel(item.questionType),
          fact: '${item.input}对应${item.correctAnswer}',
          hint:
              '甲乙东方木，丙丁南方火，戊己中央土，庚辛西方金，壬癸北方水。'
              '${_same(tianGan, _fieldFor(item.questionType), item.correctAnswer)}都是${item.correctAnswer}。',
        );
      case 'gan_yinyang':
        return TeachingNote(
          title: '天干阴阳',
          fact: '${item.input}属${item.correctAnswer}',
          hint:
              '从甲起阳阴相间。阳：${_same(tianGan, 'yinYang', '阳')}。阴：${_same(tianGan, 'yinYang', '阴')}。',
        );
      case 'gan_month':
      case 'gan_time':
        return TeachingNote(
          title: KnowledgeCatalog.questionTypeLabel(item.questionType),
          fact: '${item.input}对应${item.correctAnswer}',
          hint: '十天干按甲到癸，月份从正月排到十月，时辰从寅时排到子时。',
        );
      case 'zhi_wuxing':
        return TeachingNote(
          title: '地支五行',
          fact: '${item.input}属${item.correctAnswer}',
          hint:
              '寅卯木，巳午火，申酉金，亥子水，辰戌丑未土。'
              '${item.correctAnswer}：${_same(diZhi, 'wuXing', item.correctAnswer)}。',
        );
      case 'zhi_yinyang':
        return TeachingNote(
          title: '地支阴阳',
          fact: '${item.input}属${item.correctAnswer}',
          hint:
              '子起阳阴相间。阳：${_same(diZhi, 'yinYang', '阳')}。阴：${_same(diZhi, 'yinYang', '阴')}。',
        );
      case 'zhi_direction':
      case 'zhi_season':
      case 'zhi_month':
      case 'zhi_time':
      case 'zhi_hour':
        return TeachingNote(
          title: KnowledgeCatalog.questionTypeLabel(item.questionType),
          fact: '${item.input}对应${item.correctAnswer}',
          hint:
              '${item.correctAnswer}：${_same(diZhi, _fieldFor(item.questionType), item.correctAnswer)}。'
              '子北午南，卯东酉西。',
        );
      case 'zhi_liuhe':
        return TeachingNote(
          title: '六合',
          fact: '${item.input}与${item.correctAnswer}六合',
          hint: '六对：子丑、寅亥、卯戌、辰酉、巳申、午未。',
        );
      case 'zhi_sanhe':
        return TeachingNote(
          title: '三合',
          fact: '${item.correctAnswer}是三合',
          hint: '申子辰合水，亥卯未合木，寅午戌合火，巳酉丑合金。',
        );
      case 'zhi_sanxing':
        return TeachingNote(
          title: '三刑',
          fact: '${item.correctAnswer}是三刑',
          hint: '寅巳申为无恩之刑，丑戌未为持势之刑，子卯为无礼之刑。',
        );
      case 'zhi_zixing':
        return TeachingNote(
          title: '自刑',
          fact: '${item.correctAnswer}自刑',
          hint: '辰、午、酉、亥自己刑自己。',
        );
      case 'zhi_liuchong':
        return TeachingNote(
          title: '六冲',
          fact: '${item.input}与${item.correctAnswer}六冲',
          hint: '地支循环上隔六位。子午、丑未、寅申、卯酉、辰戌、巳亥。',
        );
      case 'zhi_liuhai':
        return TeachingNote(
          title: '六害',
          fact: '${item.input}与${item.correctAnswer}六害',
          hint: '子未、丑午、寅巳、卯辰、申亥、酉戌。',
        );
      case 'zhi_poxiang':
        return TeachingNote(
          title: '相破',
          fact: '${item.input}与${item.correctAnswer}相破',
          hint: '子酉、丑辰、寅亥、卯午、巳申、未戌。',
        );
      case 'finger_forward':
        return TeachingNote(
          title: '十二支指诀',
          fact: '${item.input}在${item.correctAnswer}',
          hint: '每个地支固定在一个指节上。完整对照可以点「查表」看。',
        );
      case 'finger_reverse':
        return TeachingNote(
          title: '十二支指诀',
          fact: '${item.input}是${item.correctAnswer}',
          hint: '每个地支固定在一个指节上。完整对照可以点「查表」看。',
        );
      case 'wuxing_sheng':
        return TeachingNote(
          title: '五行相生',
          fact: '${item.input}生${item.correctAnswer}',
          hint: _cycle(wuXingSheng, '生'),
        );
      case 'wuxing_ke':
        return TeachingNote(
          title: '五行相克',
          fact: '${item.input}克${item.correctAnswer}',
          hint: _cycle(wuXingKe, '克'),
        );
      case KnowledgeCatalog.changShengStageType:
        final index = changShengCycle.indexOf(item.input);
        return TeachingNote(
          title: '十二长生阶段',
          fact: '${item.correctAnswer}排第${index + 1}',
          hint:
              '口诀：${changShengCycle.join('、')}，十二个阶段依次轮转，养之后又回到长生。'
              '推算时从日支五行的长生起点开始，按地支顺数，每进一支换一个阶段。',
        );
      case KnowledgeCatalog.changShengStartType:
        return TeachingNote(
          title: '十二长生起点',
          fact: '${item.input}的长生在${item.correctAnswer}',
          hint:
              '口诀：木长生在亥，火长生在寅，金长生在巳，水土长生在申。'
              '推算时先看日支属什么五行，再从这个起点按地支顺数到爻支。',
        );
      case KnowledgeCatalog.kongWangType:
        return TeachingNote(
          title: '算空亡',
          fact: '${item.input}旬空${item.correctAnswer}',
          hint:
              '从日干倒着数到甲，日支退同样的位数得到旬首，再从旬首往回数两位。'
              '甲子旬戌亥，甲戌旬申酉，甲申旬午未，甲午旬辰巳，甲辰旬寅卯，甲寅旬子丑。',
        );
      case 'gua_to_xiang':
        return TeachingNote(
          title: '六十四卦',
          fact: '「${item.input}」的卦象是${item.correctAnswer}',
          hint: _guaHint(item.correctAnswer),
        );
      case 'xiang_to_gua':
        return TeachingNote(
          title: '六十四卦',
          fact: '卦象${item.input}是${item.correctAnswer}',
          hint: _guaHint(item.input),
        );
      default:
        return TeachingNote(
          title: KnowledgeCatalog.questionTypeLabel(item.questionType),
          fact: item.correctAnswer,
          hint: item.text,
        );
    }
  }

  static TeachingNote? forKey(String itemKey) {
    final separator = itemKey.indexOf(':');
    if (separator <= 0 || separator >= itemKey.length - 1) return null;
    final item = KnowledgeCatalog.find(
      itemKey.substring(0, separator),
      itemKey.substring(separator + 1),
    );
    if (item == null) return null;
    return forItem(item);
  }

  /// 答错讲解。推算题按这道题的日支、爻支分步讲，其余同 [forKey]。
  static TeachingNote? forQuestion(Question question) {
    final riGan = question.context['riGan'];
    final riZhi = question.context['riZhi'];
    final yaoZhi = question.context['yaoZhi'];
    if (question.questionType == KnowledgeCatalog.kongWangType &&
        riGan != null &&
        riZhi != null) {
      final steps = kongWangSteps(riGan, riZhi);
      if (steps.isNotEmpty) {
        return TeachingNote(
          title: '算空亡',
          fact: '$riGan$riZhi日空${question.correctAnswer}',
          hint: steps.join(' → '),
        );
      }
    }
    if (KnowledgeCatalog.isChangShengRule(question.questionType) &&
        riZhi != null &&
        yaoZhi != null) {
      final steps = changShengSteps(riZhi, yaoZhi);
      if (steps.isNotEmpty) {
        return TeachingNote(
          title: '十二长生',
          fact: '日支$riZhi、爻支$yaoZhi，处于${question.correctAnswer}',
          hint: steps.join(' → '),
        );
      }
    }
    return forKey(question.itemKey);
  }

  /// 推算步骤：日支五行 → 长生起点 → 顺数到爻支 → 阶段。
  /// 例如午日酉爻：日支午属火 → 火长生在寅 → 从寅顺数到酉：寅长生、…、酉死 → 死。
  static List<String> changShengSteps(String riZhi, String yaoZhi) {
    final element = zhiWuXing[riZhi];
    final start = element == null ? null : wuXingChangShengStart[element];
    final startIndex = start == null ? -1 : diZhiCycle.indexOf(start);
    final yaoIndex = diZhiCycle.indexOf(yaoZhi);
    if (startIndex < 0 || yaoIndex < 0) return const [];
    final count = (yaoIndex - startIndex) % diZhiCycle.length + 1;
    final walk = [
      for (var i = 0; i < count; i++)
        '${diZhiCycle[(startIndex + i) % diZhiCycle.length]}${changShengCycle[i]}',
    ];
    return [
      '日支$riZhi属$element',
      '$element长生在$start',
      '从$start顺数到$yaoZhi：${walk.join('、')}',
      changShengCycle[count - 1],
    ];
  }

  static String _guaHint(String xiang) {
    if (xiang.length < 2) return '卦象写成上卦加下卦。';
    final symbol = getGuaSymbol(xiang);
    return '卦象两个字，前一个是上卦，后一个是下卦。$xiang是上${xiang[0]}下${xiang[1]}（$symbol）。';
  }

  static String _fieldFor(String questionType) {
    switch (questionType) {
      case 'gan_wuxing':
      case 'zhi_wuxing':
        return 'wuXing';
      case 'gan_direction':
      case 'zhi_direction':
        return 'direction';
      case 'gan_season':
      case 'zhi_season':
        return 'season';
      case 'zhi_month':
        return 'month';
      case 'zhi_time':
        return 'time';
      case 'zhi_hour':
        return 'hour';
      default:
        return 'name';
    }
  }

  static String _same(
    List<Map<String, String>> rows,
    String field,
    String value,
  ) {
    return rows
        .where((row) => row[field] == value)
        .map((row) => row['name']!)
        .join('、');
  }

  static String _cycle(Map<String, String> relation, String verb) {
    const order = ['木', '火', '土', '金', '水'];
    return order.map((name) => '$name$verb${relation[name]}').join('，');
  }
}
