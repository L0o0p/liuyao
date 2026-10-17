import '../data/di_zhi.dart';
import '../data/knowledge_catalog.dart';
import '../data/tian_gan.dart';
import '../data/zhi_relations.dart';
import '../models/question.dart';
import '../models/wrong_question_record.dart';

/// 从错题记录重建题目。
///
/// 已有 questionType 和 input 时走知识点目录，正确答案固定，错误选项重新抽取。
/// 旧记录缺这两个字段时，仍从题干反推。
class QuestionReconstructor {
  static final _wuxing = ["木", "火", "土", "金", "水"];

  static Question reconstructFromRecord(WrongQuestionRecord record) {
    if (record.questionType == KnowledgeCatalog.legacyChangShengType) {
      final parts = record.input.split('_');
      if (KnowledgeCatalog.legacyChangShengRules(record.input) != null) {
        return KnowledgeCatalog.changShengQuestion(
          riZhi: parts[0],
          yaoZhi: parts[1],
          ruleType: KnowledgeCatalog.changShengStartType,
        );
      }
    }
    final question = KnowledgeCatalog.generateQuestion(
      record.questionType,
      record.input,
    );
    return Question(
      text: question.text,
      options: question.options,
      correctAnswer: question.correctAnswer,
      questionType: record.questionType,
      input: record.input,
    );
  }

  /// 根据题目内容推断题目类型和输入参数。
  /// 题干能对上目录时直接用目录；对不上再走旧题干格式。
  static Map<String, String>? inferQuestionTypeAndInput(Question question) {
    final byText = KnowledgeCatalog.items
        .where((item) => item.text == question.text)
        .toList();
    if (byText.length == 1) {
      return {
        'questionType': byText.single.questionType,
        'input': byText.single.input,
      };
    }
    if (byText.length > 1) {
      final byAnswer = byText
          .where((item) => item.correctAnswer == question.correctAnswer)
          .toList();
      if (byAnswer.length == 1) {
        return {
          'questionType': byAnswer.single.questionType,
          'input': byAnswer.single.input,
        };
      }
    }
    return _inferLegacy(question);
  }

  static Map<String, String>? _inferLegacy(Question question) {
    final text = question.text;

    if (text.contains('属于什么五行？')) {
      for (final gan in tianGan) {
        if (text.startsWith(gan['name']!)) {
          return {'questionType': 'gan_wuxing', 'input': gan['name']!};
        }
      }
      for (final zhi in diZhi) {
        if (text.startsWith(zhi['name']!)) {
          return {'questionType': 'zhi_wuxing', 'input': zhi['name']!};
        }
      }
    }

    if (text.contains('属于阴还是阳？')) {
      for (final gan in tianGan) {
        if (text.startsWith(gan['name']!)) {
          return {'questionType': 'gan_yinyang', 'input': gan['name']!};
        }
      }
      for (final zhi in diZhi) {
        if (text.startsWith(zhi['name']!)) {
          return {'questionType': 'zhi_yinyang', 'input': zhi['name']!};
        }
      }
    }

    if (text.contains('六合？')) {
      final match = RegExp(r'谁和(.+) 六合？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_liuhe', 'input': match.group(1)!};
      }
    }

    if (text.contains('六冲？')) {
      final match = RegExp(r'谁和(.+) 六冲？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_liuchong', 'input': match.group(1)!};
      }
    }

    if (text.contains('六害？')) {
      final match = RegExp(r'谁和(.+) 六害？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_liuhai', 'input': match.group(1)!};
      }
    }

    if (text.contains('相破？')) {
      final match = RegExp(r'谁和(.+) 相破？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_poxiang', 'input': match.group(1)!};
      }
    }

    if (text.contains('对应什么方位？')) {
      for (final gan in tianGan) {
        if (text.startsWith(gan['name']!)) {
          return {'questionType': 'gan_direction', 'input': gan['name']!};
        }
      }
      for (final zhi in diZhi) {
        if (text.startsWith(zhi['name']!)) {
          return {'questionType': 'zhi_direction', 'input': zhi['name']!};
        }
      }
    }

    if (text.contains('对应什么季节？')) {
      for (final gan in tianGan) {
        if (text.startsWith(gan['name']!)) {
          return {'questionType': 'gan_season', 'input': gan['name']!};
        }
      }
      for (final zhi in diZhi) {
        if (text.startsWith(zhi['name']!)) {
          return {'questionType': 'zhi_season', 'input': zhi['name']!};
        }
      }
    }

    if (text.contains('在手指的什么位置？')) {
      for (final zhi in diZhi) {
        if (text.startsWith(zhi['name']!)) {
          return {'questionType': 'finger_forward', 'input': zhi['name']!};
        }
      }
    }

    if (text.contains('生什么？')) {
      for (final wx in _wuxing) {
        if (text.startsWith(wx)) {
          return {'questionType': 'wuxing_sheng', 'input': wx};
        }
      }
    }

    if (text.contains('克什么？')) {
      for (final wx in _wuxing) {
        if (text.startsWith(wx)) {
          return {'questionType': 'wuxing_ke', 'input': wx};
        }
      }
    }

    if (text.contains('的卦象是哪个？')) {
      final match = RegExp(r'卦「(.+)」的卦象是哪个？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'gua_to_xiang', 'input': match.group(1)!};
      }
    }

    if (text.contains('对应的卦名是哪个？')) {
      final match = RegExp(r'卦象「(.+)」对应的卦名是哪个？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'xiang_to_gua', 'input': match.group(1)!};
      }
    }

    // 旧题干「若日支为『午』，某爻地支为『酉』」和现在的推算题干，都归到日支五行的起点卡。
    if (text.contains('十二长生')) {
      final match = RegExp(
        r'日支(?:为『)?(.)』?[，、](?:某爻地支为『|爻支)(.)',
      ).firstMatch(text);
      final riZhi = match?.group(1);
      final yaoZhi = match?.group(2);
      if (riZhi != null &&
          KnowledgeCatalog.legacyChangShengRules('${riZhi}_$yaoZhi') != null) {
        return {
          'questionType': KnowledgeCatalog.changShengStartType,
          'input': zhiWuXing[riZhi]!,
        };
      }
    }

    return null;
  }
}
