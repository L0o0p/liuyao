import 'dart:math';

import '../data/gua_data.dart';
import '../data/knowledge_catalog.dart';
import '../models/question.dart';

/// 题目生成器的薄封装。真正的出题在 [KnowledgeCatalog.generateQuestion]。
class Questions {
  static final _rnd = Random();

  static Question _one(String type, String? input) {
    final resolved = input ?? KnowledgeCatalog.randomInput(type, _rnd);
    return KnowledgeCatalog.generateQuestion(type, resolved, random: _rnd);
  }

  /// 三合、三刑的旧调用会传入带空格或逗号的组合，先收成目录里的键。
  static String _groupInput(String type, String input) {
    if (KnowledgeCatalog.find(type, input) != null) return input;
    final compact = input.replaceAll(RegExp(r'[\s,]'), '');
    if (KnowledgeCatalog.find(type, compact) != null) return compact;
    return input;
  }

  static Question generateZhiWuXingQuestion({String? zhi}) =>
      _one('zhi_wuxing', zhi);

  static Question generateGanWuXingQuestion({String? gan}) =>
      _one('gan_wuxing', gan);

  static Question generateGanYinYangQuestion({String? gan}) =>
      _one('gan_yinyang', gan);

  static Question generateZhiYinYangQuestion({String? zhi}) =>
      _one('zhi_yinyang', zhi);

  static Question generateLiuHeQuestion({String? zhi}) =>
      _one('zhi_liuhe', zhi);

  static Question generateSanHeQuestion({String? input}) =>
      _one('zhi_sanhe', input == null ? null : _groupInput('zhi_sanhe', input));

  static Question generateSanXingQuestion({String? input}) => _one(
    'zhi_sanxing',
    input == null ? null : _groupInput('zhi_sanxing', input),
  );

  static Question generateZiXingQuestion({String? input}) =>
      _one('zhi_zixing', input);

  static Question generateGanDirectionQuestion({String? gan}) =>
      _one('gan_direction', gan);

  static Question generateZhiDirectionQuestion({String? zhi}) =>
      _one('zhi_direction', zhi);

  static Question generateGanSeasonQuestion({String? gan}) =>
      _one('gan_season', gan);

  static Question generateZhiSeasonQuestion({String? zhi}) =>
      _one('zhi_season', zhi);

  static Question generateGanMonthQuestion({String? gan}) =>
      _one('gan_month', gan);

  static Question generateZhiMonthQuestion({String? zhi}) =>
      _one('zhi_month', zhi);

  static Question generateGanTimeQuestion({String? gan}) =>
      _one('gan_time', gan);

  static Question generateZhiTimeQuestion({String? zhi}) =>
      _one('zhi_time', zhi);

  static Question generateZhiHourQuestion({String? zhi}) =>
      _one('zhi_hour', zhi);

  static Question generateFingerJointForwardQuestion({String? zhi}) =>
      _one('finger_forward', zhi);

  static Question generateFingerJointReverseQuestion({String? input}) =>
      _one('finger_reverse', input);

  static Question generateChangShengQuestion({String? input}) =>
      _one('changsheng', input);

  static Question generateWuXingShengQuestion({String? wuxing}) =>
      _one('wuxing_sheng', wuxing);

  static Question generateWuXingKeQuestion({String? wuxing}) =>
      _one('wuxing_ke', wuxing);

  static Question generateTianGanDizhiComprehensiveQuestion() =>
      KnowledgeCatalog.randomQuestionForModule(
        'tiangandizhi_comprehensive',
        _rnd,
      );

  static Question generateGuaToXiangQuestion() => _one('gua_to_xiang', null);

  static Question generateGuaToXiangQuestionFor(String correctGua) =>
      _one('gua_to_xiang', correctGua);

  static Question generateXiangToGuaQuestion() => _one('xiang_to_gua', null);

  static Question generateXiangToGuaQuestionFor(String correctGua) {
    final xiang = getGuaXiang(correctGua);
    if (xiang == null) {
      throw ArgumentError('未知卦名: $correctGua');
    }
    return _one('xiang_to_gua', xiang);
  }

  static Question generate64GuaQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('64gua', _rnd);
}
