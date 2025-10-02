import 'package:liuyao/data/di_zhi.dart';
import 'package:liuyao/data/zhi_relations.dart';
import '../data/tian_gan.dart';
import 'rule_functions.dart';
import '../models/question.dart';
import 'dart:math';

class QuestionFactory {
  static final _rnd = Random();
  static final _wuxing = ["木", "火", "土", "金", "水"];

  // 刑冲合害
  static Question generateXingChongHeChongQuestion() {
    // 题型生成器池子
    final generators = [
      generateLiuHeQuestion,
      generateSanHeQuestion,
      generateSanXingQuestion,
      generateZiXingQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  // 天干地支五行阴阳
  static Question generateTianGanDizhiQuestion() {
    // 题型生成器池子
    final generators = [
      generateGanWuXingQuestion,
      generateZhiWuXingQuestion,
      generateGanYinYangQuestion,
      generateZhiYinYangQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  // 天干地支方位时间
  static Question generateDirectionTimeQuestion() {
    // 题型生成器池子
    final generators = [
      generateGanDirectionQuestion,
      generateZhiDirectionQuestion,
      generateGanSeasonQuestion,
      generateZhiSeasonQuestion,
      generateGanMonthQuestion,
      generateZhiMonthQuestion,
      generateGanTimeQuestion,
      generateZhiTimeQuestion,
      generateZhiHourQuestion,
    ];

    // 随机选择一个生成器
    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  // 地支指诀（包含正向和反向两种题型）
  static Question generateFingerJointQuestion() {
    // 随机选择题型：正向（地支→指节）或反向（指节→地支）
    final generators = [
      _generateFingerJointForwardQuestion,
      _generateFingerJointReverseQuestion,
    ];

    final generator = generators[_rnd.nextInt(generators.length)];
    return generator();
  }

  // 正向指诀：从地支选指节
  static Question _generateFingerJointForwardQuestion() {
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

  // 反向指诀：从指节选地支
  static Question _generateFingerJointReverseQuestion() {
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

  // 十二长生
  static Question generateChangShengQuestion() {
    // 随机一个“日支”作为卜日
    final riZhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    // 随机一个“爻地支”
    final yaoZhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;

    final correct = getWuXingChangSheng(riZhi, yaoZhi);

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
  // ==================================================================

  // 地支五行
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

  // 天干五行
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

  // 天干阴阳
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

  // 地支阴阳
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

  // 六合
  static Question generateLiuHeQuestion() {
    final zhi = diZhi[_rnd.nextInt(diZhi.length)]["name"]!;
    final List<String> diZhiNames = diZhi.map((item) => item["name"]!).toList();
    final correct = getLiuHe(zhi);

    final options = diZhiNames;
    return Question(
      text: "谁和$zhi 六合？",
      options: options,
      correctAnswer: correct,
    );
  }

  // 三合
  static Question generateSanHeQuestion() {
    // 随机抽一个三合组合作为正确答案
    final correctGroup = sanHe[_rnd.nextInt(sanHe.length)];

    // 复制一份list并打乱，去掉正确答案
    final otherGroups = List<List<String>>.from(sanHe)..remove(correctGroup);
    otherGroups.shuffle(_rnd);

    // 从剩下的组选 3 个当错误答案
    final wrongGroups = otherGroups.take(3).toList();

    // 把正确组和错误组合并
    final allGroups = [correctGroup, ...wrongGroups];
    allGroups.shuffle(_rnd); // 打乱顺序

    // 把每个组合拼成字符串作为选项
    final options = allGroups.map((group) => group.join(" ")).toList();

    return Question(
      text: "以下哪个是三合组合？",
      options: options,
      correctAnswer: correctGroup.join(" "),
    );
  }

  // 三刑
  static Question generateSanXingQuestion() {
    // 过滤掉长度小于3的（只要三刑组合）
    final sanXingGroups = sanXing.where((g) => g.length >= 3).toList();

    // 随机抽一个三刑组合作为正确答案
    final correctGroup = sanXingGroups[_rnd.nextInt(sanXingGroups.length)];

    // 复制并打乱，去掉正确答案
    final otherGroups = List<List<String>>.from(sanXingGroups)
      ..remove(correctGroup);
    otherGroups.shuffle(_rnd);

    // 随机拿三个错误答案
    final wrongGroups = otherGroups.take(3).toList();

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

  // 自刑
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

  // 天干方位
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

  // 地支方位
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

  // 天干季节
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

  // 地支季节
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

  // 天干月份
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

  // 地支月份
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

  // 天干时辰
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

  // 地支时辰
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

  // 地支小时
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
      text: "$zhi 对应的小时是？",
      options: options,
      correctAnswer: correct,
    );
  }
}
