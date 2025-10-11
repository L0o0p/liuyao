import '../models/question.dart';
import 'questions.dart';
import 'dart:math';

/// 题目工厂类
/// 负责根据不同的学习模块类型生成相应的题目
/// 作为 study_module_screen.dart 的主要接口
class QuestionFactory {
  static final _rnd = Random();

  // ========== 主要模块题目生成器 ==========

  /// 刑冲合害题目生成器
  /// 包含六合、三合、三刑、自刑等题目类型
  static Question generateXingChongHeChongQuestion() {
    // 题型生成器池子
    final generators = [
      Questions.generateLiuHeQuestion,
      Questions.generateSanHeQuestion,
      Questions.generateSanXingQuestion,
      Questions.generateZiXingQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  /// 天干地支五行阴阳题目生成器
  /// 包含天干五行、地支五行等基础题目
  static Question generateTianGanDizhiQuestion() {
    // 题型生成器池子
    final generators = [
      Questions.generateGanWuXingQuestion,
      Questions.generateZhiWuXingQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  /// 天干地支阴阳题目生成器
  /// 专门生成阴阳相关的题目
  static Question generateTianGanDizhiYinYangQuestion() {
    // 题型生成器池子
    final generators = [
      Questions.generateGanYinYangQuestion,
      Questions.generateZhiYinYangQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  /// 天干地支方位题目生成器
  /// 生成方位、季节、月份等相关的题目
  static Question generateDirectionQuestion() {
    // 题型生成器池子（仅方位相关）
    final generators = [
      Questions.generateGanDirectionQuestion,
      Questions.generateZhiDirectionQuestion,
      Questions.generateGanSeasonQuestion,
      Questions.generateZhiSeasonQuestion,
      Questions.generateGanMonthQuestion,
      Questions.generateZhiMonthQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  /// 天干地支时间题目生成器
  /// 只包含时间属性（时辰、时间段等）
  static Question generateTimeQuestion() {
    // 题型生成器池子（仅时间相关）
    final generators = [
      Questions.generateGanTimeQuestion,
      // Questions.generateZhiTimeQuestion,
      Questions.generateZhiHourQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  /// 地支指诀题目生成器
  /// 包含正向和反向两种题型
  static Question generateFingerJointQuestion() {
    // 随机选择题型：正向（地支→指节）或反向（指节→地支）
    final generators = [
      Questions.generateFingerJointForwardQuestion,
      Questions.generateFingerJointReverseQuestion,
    ];

    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  /// 十二长生题目生成器
  static Question generateChangShengQuestion() {
    return Questions.generateChangShengQuestion();
  }

  /// 天干地支综合题目生成器
  /// 包含所有类型的综合练习
  static Question generateTianGanDizhiComprehensiveQuestion() {
    return Questions.generateTianGanDizhiComprehensiveQuestion();
  }

  /// 六十四卦题目生成器
  /// 包含卦名到卦象和卦象到卦名的配对题目
  static Question generate64GuaQuestion() {
    return Questions.generate64GuaQuestion();
  }

  // ========== 基础题目生成器（供内部调用） ==========

  /// 天干五行题目生成器
  static Question generateGanWuXingQuestion() {
    return Questions.generateGanWuXingQuestion();
  }

  /// 五行生题目生成器
  static Question generateWuXingShengQuestion() {
    return Questions.generateWuXingShengQuestion();
  }

  /// 五行克题目生成器
  static Question generateWuXingKeQuestion() {
    return Questions.generateWuXingKeQuestion();
  }
}
