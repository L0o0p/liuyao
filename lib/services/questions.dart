import 'package:liuyao/data/di_zhi.dart';
import 'package:liuyao/data/wu_xing.dart';
import 'package:liuyao/data/zhi_relations.dart';
import '../data/tian_gan.dart';
import '../data/gua_data.dart';
import 'rule_functions.dart';
import '../models/question.dart';
import 'dart:math';

/// 题目生成器集合
/// 包含所有具体的题目生成方法，供 QuestionFactory 调用
class Questions {
  static final _rnd = Random();
  static final _wuxing = ["木", "火", "土", "金", "水"];

  // ========== 基础五行阴阳题目生成器 ==========

  /// 地支五行题目生成器
  static Question generateZhiWuXingQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiWuXing(zhi);

    final options = _wuxing;
    return Question(
      text: "$zhi 属于什么五行？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 天干五行题目生成器
  static Question generateGanWuXingQuestion() {
    final gan = tianGan[_rnd.nextInt(tianGan.length)]["name"]!;
    final correct = getGanWuXing(gan);

    final options = _wuxing;
    return Question(
      text: "$gan 属于什么五行？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 天干阴阳题目生成器
  static Question generateGanYinYangQuestion() {
    final gan = tianGan[_rnd.nextInt(tianGan.length)]["name"]!;
    final correct = getGanYinYang(gan);

    final options = ["阳", "阴"];
    return Question(
      text: "$gan 属于阴还是阳？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 地支阴阳题目生成器
  static Question generateZhiYinYangQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiYinYang(zhi);

    final options = ["阳", "阴"];
    return Question(
      text: "$zhi 属于阴还是阳？",
      options: options,
      correctAnswer: correct,
    );
  }

  // ========== 刑冲合害题目生成器 ==========

  /// 六合题目生成器
  static Question generateLiuHeQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getLiuHe(zhi);

    // 生成错误选项：从其他地支中随机选择3个
    final allDiZhiNames = diZhi.map((item) => item["name"]!).toList();
    final wrongOptions = List<String>.from(allDiZhiNames)..remove(correct);
    wrongOptions.shuffle(_rnd);

    // 组合选项：正确答案 + 3个错误选项
    final options = [correct, ...wrongOptions.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "谁和$zhi 六合？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 三合题目生成器
  static Question generateSanHeQuestion() {
    // 随机抽一个三合组合作为正确答案
    final correctGroup = sanHe[_rnd.nextInt(sanHe.length)];

    // 生成三个错误选项，每个都是随机选择3个地支的组合
    final allZhi = diZhi.map((d) => d["name"]!).toList();
    final List<List<String>> wrongGroups = [];

    // 生成3个错误选项
    for (int i = 0; i < 3; i++) {
      List<String> wrongGroup;
      bool isDuplicate;
      int tryCount = 0;

      do {
        // 随机选择3个地支组成错误选项
        final List<String> candidate = List<String>.from(allZhi)..shuffle(_rnd);
        wrongGroup = candidate.take(3).toList();

        // 检查是否与任何真实三合组合重复（顺序无关）
        final wrongSet = wrongGroup.toSet();
        isDuplicate = sanHe.any((realGroup) {
          final realSet = realGroup.toSet();
          return wrongSet.difference(realSet).isEmpty &&
              realSet.difference(wrongSet).isEmpty;
        });

        tryCount++;
        // 防止死循环，最多尝试50次
        if (tryCount > 50) break;
      } while (isDuplicate);

      wrongGroups.add(wrongGroup);
    }

    // 合并所有选项
    final allGroups = [correctGroup, ...wrongGroups]..shuffle(_rnd);

    // 把每个组合拼成字符串
    final options = allGroups.map((g) => g.join(" ")).toList();

    return Question(
      text: "以下哪个是三合组合？",
      options: options,
      correctAnswer: correctGroup.join(" "),
    );
  }

  /// 三刑题目生成器
  static Question generateSanXingQuestion() {
    // 不再过滤三刑组合，直接使用全部三刑数据
    final sanXingGroups = sanXing;

    // 随机抽一个三刑组合作为正确答案
    final correctGroup = sanXingGroups[_rnd.nextInt(sanXingGroups.length)];

    // 生成三个错误选项，每个都是随机选择3个地支的组合
    final allZhi = diZhi.map((d) => d["name"]!).toList();
    final List<List<String>> wrongGroups = [];

    // 生成3个错误选项
    for (int i = 0; i < 3; i++) {
      List<String> wrongGroup;
      bool isDuplicate;
      int tryCount = 0;

      do {
        // 随机选择3个地支组成错误选项
        final List<String> candidate = List<String>.from(allZhi)..shuffle(_rnd);
        wrongGroup = candidate.take(3).toList();

        // 检查是否与任何真实三刑组合重复（顺序无关）
        final wrongSet = wrongGroup.toSet();
        isDuplicate = sanXing.any((realGroup) {
          final realSet = realGroup.toSet();
          return wrongSet.difference(realSet).isEmpty &&
              realSet.difference(wrongSet).isEmpty;
        });

        tryCount++;
        // 防止死循环，最多尝试50次
        if (tryCount > 50) break;
      } while (isDuplicate);

      wrongGroups.add(wrongGroup);
    }

    // 合并所有选项
    final allGroups = [correctGroup, ...wrongGroups]..shuffle(_rnd);

    // 把每个组合拼成字符串
    final options = allGroups.map((g) => g.join(" ")).toList();

    return Question(
      text: "以下哪个是三刑组合？",
      options: options,
      correctAnswer: correctGroup.join(" "),
    );
  }

  /// 自刑题目生成器
  static Question generateZiXingQuestion() {
    // 正确答案：一个随机自刑地支
    final keys = ziXing.keys.toList();
    final correct = keys[_rnd.nextInt(keys.length)];

    // 随机三个错误答案（不在自刑的keys里）
    final allZhi = diZhi.map((d) => d["name"]!).toList();
    final nonZiXing = allZhi.where((z) => !keys.contains(z)).toList();
    nonZiXing.shuffle(_rnd);

    final options = [correct, ...nonZiXing.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "以下哪个地支有自刑？",
      options: options,
      correctAnswer: correct,
    );
  }

  // ========== 方位时间相关问题生成器 ==========

  /// 天干方位题目生成器
  static Question generateGanDirectionQuestion() {
    final gan = tianGan[_rnd.nextInt(tianGan.length)]["name"]!;
    final correct = getGanDirection(gan);

    final allDirections = ["东", "南", "西", "北", "中", "东北", "东南", "西南", "西北"];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongDirections = List<String>.from(allDirections)..remove(correct);
    wrongDirections.shuffle(_rnd);

    final options = [correct, ...wrongDirections.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$gan 对应的方位是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 地支方位题目生成器
  static Question generateZhiDirectionQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiDirection(zhi);

    final allDirections = ["东", "南", "西", "北", "中", "东北", "东南", "西南", "西北"];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongDirections = List<String>.from(allDirections)..remove(correct);
    wrongDirections.shuffle(_rnd);

    final options = [correct, ...wrongDirections.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$zhi 对应的方位是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 天干季节题目生成器
  static Question generateGanSeasonQuestion() {
    final gan = tianGan[_rnd.nextInt(tianGan.length)]["name"]!;
    final correct = getGanSeason(gan);

    final allSeasons = ["春", "夏", "长夏", "秋", "冬"];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongSeasons = List<String>.from(allSeasons)..remove(correct);
    wrongSeasons.shuffle(_rnd);

    final options = [correct, ...wrongSeasons.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$gan 对应的季节是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 地支季节题目生成器
  static Question generateZhiSeasonQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiSeason(zhi);

    final allSeasons = ["春", "夏", "长夏", "秋", "冬"];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongSeasons = List<String>.from(allSeasons)..remove(correct);
    wrongSeasons.shuffle(_rnd);

    final options = [correct, ...wrongSeasons.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$zhi 对应的季节是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 天干月份题目生成器
  static Question generateGanMonthQuestion() {
    final gan = tianGan[_rnd.nextInt(tianGan.length)]["name"]!;
    final correct = getGanMonth(gan);

    final allMonths = [
      "正月",
      "二月",
      "三月",
      "四月",
      "五月",
      "六月",
      "七月",
      "八月",
      "九月",
      "十月",
      "十一月",
      "十二月",
    ];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongMonths = List<String>.from(allMonths)..remove(correct);
    wrongMonths.shuffle(_rnd);

    final options = [correct, ...wrongMonths.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$gan 对应的月份是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 地支月份题目生成器
  static Question generateZhiMonthQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiMonth(zhi);

    final allMonths = [
      "正月",
      "二月",
      "三月",
      "四月",
      "五月",
      "六月",
      "七月",
      "八月",
      "九月",
      "十月",
      "十一月",
      "十二月",
    ];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongMonths = List<String>.from(allMonths)..remove(correct);
    wrongMonths.shuffle(_rnd);

    final options = [correct, ...wrongMonths.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$zhi 对应的月份是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 天干时辰题目生成器
  static Question generateGanTimeQuestion() {
    final gan = tianGan[_rnd.nextInt(tianGan.length)]["name"]!;
    final correct = getGanTime(gan);

    final allTimes = [
      "子时",
      "丑时",
      "寅时",
      "卯时",
      "辰时",
      "巳时",
      "午时",
      "未时",
      "申时",
      "酉时",
      "戌时",
      "亥时",
    ];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongTimes = List<String>.from(allTimes)..remove(correct);
    wrongTimes.shuffle(_rnd);

    final options = [correct, ...wrongTimes.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$gan 对应的时辰是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 地支时辰题目生成器
  static Question generateZhiTimeQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiTime(zhi);

    final allTimes = [
      "子时",
      "丑时",
      "寅时",
      "卯时",
      "辰时",
      "巳时",
      "午时",
      "未时",
      "申时",
      "酉时",
      "戌时",
      "亥时",
    ];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongTimes = List<String>.from(allTimes)..remove(correct);
    wrongTimes.shuffle(_rnd);

    final options = [correct, ...wrongTimes.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$zhi 对应的时辰是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 地支小时题目生成器
  static Question generateZhiHourQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiHour(zhi);

    final allHours = [
      "23-1",
      "1-3",
      "3-5",
      "5-7",
      "7-9",
      "9-11",
      "11-13",
      "13-15",
      "15-17",
      "17-19",
      "19-21",
      "21-23",
    ];
    // 移除正确答案，然后随机选择3个错误选项
    final wrongHours = List<String>.from(allHours)..remove(correct);
    wrongHours.shuffle(_rnd);

    final options = [correct, ...wrongHours.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$zhi 对应的时间段是？",
      options: options,
      correctAnswer: correct,
    );
  }

  // ========== 地支指诀题目生成器 ==========

  /// 正向指诀：从地支选指节
  static Question generateFingerJointForwardQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final correct = getZhiFingerJoint(zhi);

    // 获取所有指节选项
    final allFingerJoints = [
      "无名指根部",
      "无名指第二节",
      "无名指第三节",
      "无名指指尖",
      "中指指尖",
      "中指第三节",
      "中指第二节",
      "中指根部",
      "食指根部",
      "食指第二节",
      "食指第三节",
      "食指指尖",
    ];

    // 移除正确答案，然后随机选择3个错误选项
    final wrongOptions = List<String>.from(allFingerJoints)..remove(correct);
    wrongOptions.shuffle(_rnd);

    final options = [correct, ...wrongOptions.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$zhi 对应的指节是？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 反向指诀：从指节选地支
  static Question generateFingerJointReverseQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final fingerJoint = getZhiFingerJoint(zhi);
    final correct = zhi;

    // 获取所有地支选项
    final allZhi = diZhi.map((d) => d["name"]!).toList();

    // 移除正确答案，然后随机选择3个错误选项
    final wrongOptions = List<String>.from(allZhi)..remove(correct);
    wrongOptions.shuffle(_rnd);

    final options = [correct, ...wrongOptions.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "$fingerJoint 对应的地支是？",
      options: options,
      correctAnswer: correct,
    );
  }

  // ========== 十二长生题目生成器 ==========

  /// 十二长生题目生成器
  static Question generateChangShengQuestion() {
    // 随机一个"日支"作为卜日
    final riZhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    // 随机一个"爻地支"
    final yaoZhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;

    final correct = getWuXingChangSheng(riZhi, yaoZhi);

    // 如果正确答案是"未知"，重新生成题目
    if (correct == "未知") {
      return generateChangShengQuestion();
    }

    // 随机三个干扰项
    final wrong = List<String>.from(changShengCycle)..remove(correct);
    wrong.shuffle(_rnd);

    final options = [correct, ...wrong.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "若日支为『$riZhi』，某爻地支为『$yaoZhi』，此爻处于十二长生的哪一阶段？",
      options: options,
      correctAnswer: correct,
    );
  }

  // ========== 五行生克题目生成器 ==========

  /// 五行生题目生成器
  static Question generateWuXingShengQuestion() {
    final wuXingList = ["木", "火", "土", "金", "水"];
    final wuXing = wuXingList[_rnd.nextInt(wuXingList.length)];

    final correct = wuXingSheng[wuXing]!;

    final wrongOptions = List<String>.from(wuXingList)..remove(correct);
    wrongOptions.shuffle(_rnd);

    final options = [correct, ...wrongOptions.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "五行 $wuXing 所生的是什么五行？",
      options: options,
      correctAnswer: correct,
    );
  }

  /// 五行克题目生成器
  static Question generateWuXingKeQuestion() {
    final wuXingList = ["木", "火", "土", "金", "水"];
    final wuXing = wuXingList[_rnd.nextInt(wuXingList.length)];

    final correct = wuXingKe[wuXing]!;

    final wrongOptions = List<String>.from(wuXingList)..remove(correct);
    wrongOptions.shuffle(_rnd);

    final options = [correct, ...wrongOptions.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "五行 $wuXing 所克的是什么五行？",
      options: options,
      correctAnswer: correct,
    );
  }

  // ========== 天干地支综合题目生成器 ==========

  /// 天干地支综合题目生成器
  static Question generateTianGanDizhiComprehensiveQuestion() {
    // 题型生成器池子
    final generators = [
      generateGanWuXingQuestion, // 天干五行
      generateZhiWuXingQuestion, // 地支五行
      generateGanYinYangQuestion, // 天干阴阳
      generateZhiYinYangQuestion, // 地支阴阳
      generateGanDirectionQuestion, // 天干方位
      generateZhiDirectionQuestion, // 地支方位
      generateGanSeasonQuestion, // 天干季节
      generateZhiSeasonQuestion, // 地支季节
      generateGanMonthQuestion, // 天干月份
      generateZhiMonthQuestion, // 地支月份
      generateGanTimeQuestion, // 天干时间
      generateZhiTimeQuestion, // 地支时间
      generateZhiHourQuestion, // 地支小时
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  // ========== 六十四卦题目生成器 ==========

  /// 卦名到卦象题目生成器
  /// 给出卦名（如「大有」），要求选出卦象组合（如「火天」）
  static Question generateGuaToXiangQuestion() {
    // 从所有卦名中随机选择一个作为题目
    final guaNames = getAllGuaNames();
    final correctGua = guaNames[_rnd.nextInt(guaNames.length)];
    final correctXiang = getGuaXiang(correctGua)!;

    // 生成错误选项：从其他卦象中随机选择
    final allXiang = getAllGuaXiang();
    final wrongOptions = List<String>.from(allXiang)..remove(correctXiang);
    wrongOptions.shuffle(_rnd);

    // 组合选项：正确答案 + 3个错误选项
    final options = [correctXiang, ...wrongOptions.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "卦「$correctGua」的卦象是哪个？",
      options: options,
      correctAnswer: correctXiang,
    );
  }

  /// 卦象到卦名题目生成器
  /// 给出卦象组合（如「火天」），要求选出卦名（如「大有」）
  static Question generateXiangToGuaQuestion() {
    // 从所有卦名中随机选择一个作为题目
    final guaNames = getAllGuaNames();
    final correctGua = guaNames[_rnd.nextInt(guaNames.length)];
    final correctXiang = getGuaXiang(correctGua)!;

    // 生成错误选项：从其他卦名中随机选择
    final wrongOptions = List<String>.from(guaNames)..remove(correctGua);
    wrongOptions.shuffle(_rnd);

    // 组合选项：正确答案 + 3个错误选项
    final options = [correctGua, ...wrongOptions.take(3)];
    options.shuffle(_rnd);

    return Question(
      text: "卦象「$correctXiang」对应的卦名是哪个？",
      options: options,
      correctAnswer: correctGua,
    );
  }

  /// 六十四卦综合题目生成器
  /// 随机生成卦名到卦象或卦象到卦名的题目
  static Question generate64GuaQuestion() {
    // 题型生成器池子
    final generators = [
      generateGuaToXiangQuestion, // 卦名 → 卦象
      generateXiangToGuaQuestion, // 卦象 → 卦名
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }
}
