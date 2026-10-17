import 'dart:math';

import '../data/knowledge_catalog.dart';
import '../models/question.dart';

/// 按学习模块抽题。具体题目都走 [KnowledgeCatalog.generateQuestion]。
class QuestionFactory {
  static final _rnd = Random();

  static Question generateXingChongHeChongQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('hechong', _rnd);

  static Question generateTianGanDizhiQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('tiangandizhi_wuxing', _rnd);

  static Question generateTianGanDizhiYinYangQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('tiangandizhi_yinyang', _rnd);

  static Question generateDirectionQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('tiangandizhi_direction', _rnd);

  static Question generateTimeQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('tiangandizhi_time', _rnd);

  static Question generateFingerJointQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('wuxing', _rnd);

  static Question generateChangShengQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('shierchangsheng', _rnd);

  static Question generateTianGanDizhiComprehensiveQuestion() =>
      KnowledgeCatalog.randomQuestionForModule(
        'tiangandizhi_comprehensive',
        _rnd,
      );

  static Question generate64GuaQuestion() =>
      KnowledgeCatalog.randomQuestionForModule('64gua', _rnd);

  static Question generateGanWuXingQuestion() =>
      KnowledgeCatalog.randomQuestionOfType('gan_wuxing', _rnd);

  static Question generateWuXingShengQuestion() =>
      KnowledgeCatalog.randomQuestionOfType('wuxing_sheng', _rnd);

  static Question generateWuXingKeQuestion() =>
      KnowledgeCatalog.randomQuestionOfType('wuxing_ke', _rnd);
}
