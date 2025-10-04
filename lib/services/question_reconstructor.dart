import '../models/question.dart';
import '../models/wrong_question_record.dart';
import 'rule_functions.dart';
import '../data/tian_gan.dart';
import '../data/di_zhi.dart';
import '../data/gua_data.dart';

/// 题目重建器
/// 核心设计：从错题记录（questionType + input）重建完整题目对象
/// 原理：通过规则函数重新生成题干和选项，而不是从存储中读取完整题目
///
/// 优点：
/// 1. 存储空间小（只存参数，不存完整题目）
/// 2. 题目可以动态变化（选项顺序、干扰项等）
/// 3. 避免题库数据冗余
class QuestionReconstructor {
  static final _wuxing = ["木", "火", "土", "金", "水"];
  static final _yinyang = ["阳", "阴"];

  /// 从错题记录重建题目
  /// @param record 错题记录
  /// @return 重建的题目对象
  static Question reconstructFromRecord(WrongQuestionRecord record) {
    final input = record.input;
    final type = record.questionType;

    // 根据题目类型调用相应的重建函数
    switch (type) {
      // 天干相关
      case 'gan_wuxing':
        return _buildGanWuXingQuestion(input);
      case 'gan_yinyang':
        return _buildGanYinYangQuestion(input);
      case 'gan_direction':
        return _buildGanDirectionQuestion(input);
      case 'gan_season':
        return _buildGanSeasonQuestion(input);
      case 'gan_month':
        return _buildGanMonthQuestion(input);
      case 'gan_time':
        return _buildGanTimeQuestion(input);

      // 地支相关
      case 'zhi_wuxing':
        return _buildZhiWuXingQuestion(input);
      case 'zhi_yinyang':
        return _buildZhiYinYangQuestion(input);
      case 'zhi_direction':
        return _buildZhiDirectionQuestion(input);
      case 'zhi_season':
        return _buildZhiSeasonQuestion(input);
      case 'zhi_month':
        return _buildZhiMonthQuestion(input);
      case 'zhi_time':
        return _buildZhiTimeQuestion(input);
      case 'zhi_hour':
        return _buildZhiHourQuestion(input);

      // 地支关系相关
      case 'zhi_liuhe':
        return _buildLiuHeQuestion(input);
      case 'zhi_sanhe':
        return _buildSanHeQuestion(input);
      case 'zhi_sanxing':
        return _buildSanXingQuestion(input);
      case 'zhi_zixing':
        return _buildZiXingQuestion(input);
      case 'zhi_liuchong':
        return _buildLiuChongQuestion(input);
      case 'zhi_liuhai':
        return _buildLiuHaiQuestion(input);
      case 'zhi_poxiang':
        return _buildPoXiangQuestion(input);

      // 地支指诀相关
      case 'finger_forward':
        return _buildFingerForwardQuestion(input);
      case 'finger_reverse':
        return _buildFingerReverseQuestion(input);

      // 五行生克相关
      case 'wuxing_sheng':
        return _buildWuXingShengQuestion(input);
      case 'wuxing_ke':
        return _buildWuXingKeQuestion(input);

      // 长生相关
      case 'changsheng':
        return _buildChangShengQuestion(input);

      // 六十四卦相关
      case 'gua_to_xiang':
        return _buildGuaToXiangQuestion(input);
      case 'xiang_to_gua':
        return _buildXiangToGuaQuestion(input);

      default:
        throw Exception('Unknown question type: $type');
    }
  }

  // ========== 天干题目重建函数 ==========

  static Question _buildGanWuXingQuestion(String gan) {
    final correct = getGanWuXing(gan);
    return Question(
      text: "$gan 属于什么五行？",
      options: _wuxing,
      correctAnswer: correct,
    );
  }

  static Question _buildGanYinYangQuestion(String gan) {
    final correct = getGanYinYang(gan);
    return Question(
      text: "$gan 属于阴还是阳？",
      options: _yinyang,
      correctAnswer: correct,
    );
  }

  static Question _buildGanDirectionQuestion(String gan) {
    final correct = getGanDirection(gan);
    final directions = ["东", "南", "西", "北", "东南", "东北", "西南", "西北", "中央"];
    return Question(
      text: "$gan 对应什么方位？",
      options: directions,
      correctAnswer: correct,
    );
  }

  static Question _buildGanSeasonQuestion(String gan) {
    final correct = getGanSeason(gan);
    final seasons = ["春", "夏", "秋", "冬", "四季"];
    return Question(
      text: "$gan 对应什么季节？",
      options: seasons,
      correctAnswer: correct,
    );
  }

  static Question _buildGanMonthQuestion(String gan) {
    final correct = getGanMonth(gan);
    final months = [
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
    return Question(
      text: "$gan 对应什么月份？",
      options: months,
      correctAnswer: correct,
    );
  }

  static Question _buildGanTimeQuestion(String gan) {
    final correct = getGanTime(gan);
    return Question(
      text: "$gan 对应什么时段？",
      options: ["早晨", "上午", "中午", "下午", "傍晚", "夜晚", "深夜"],
      correctAnswer: correct,
    );
  }

  // ========== 地支题目重建函数 ==========

  static Question _buildZhiWuXingQuestion(String zhi) {
    final correct = getZhiWuXing(zhi);
    return Question(
      text: "$zhi 属于什么五行？",
      options: _wuxing,
      correctAnswer: correct,
    );
  }

  static Question _buildZhiYinYangQuestion(String zhi) {
    final correct = getZhiYinYang(zhi);
    return Question(
      text: "$zhi 属于阴还是阳？",
      options: _yinyang,
      correctAnswer: correct,
    );
  }

  static Question _buildZhiDirectionQuestion(String zhi) {
    final correct = getZhiDirection(zhi);
    final directions = ["东", "南", "西", "北", "东南", "东北", "西南", "西北"];
    return Question(
      text: "$zhi 对应什么方位？",
      options: directions,
      correctAnswer: correct,
    );
  }

  static Question _buildZhiSeasonQuestion(String zhi) {
    final correct = getZhiSeason(zhi);
    final seasons = ["春", "夏", "秋", "冬"];
    return Question(
      text: "$zhi 对应什么季节？",
      options: seasons,
      correctAnswer: correct,
    );
  }

  static Question _buildZhiMonthQuestion(String zhi) {
    final correct = getZhiMonth(zhi);
    final months = [
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
    return Question(
      text: "$zhi 对应什么月份？",
      options: months,
      correctAnswer: correct,
    );
  }

  static Question _buildZhiTimeQuestion(String zhi) {
    final correct = getZhiTime(zhi);
    return Question(
      text: "$zhi 对应什么时段？",
      options: ["早晨", "上午", "中午", "下午", "傍晚", "夜晚", "深夜"],
      correctAnswer: correct,
    );
  }

  static Question _buildZhiHourQuestion(String zhi) {
    final correct = getZhiHour(zhi);
    return Question(
      text: "$zhi 对应什么时辰？",
      options: [
        "23-1时",
        "1-3时",
        "3-5时",
        "5-7时",
        "7-9时",
        "9-11时",
        "11-13时",
        "13-15时",
        "15-17时",
        "17-19时",
        "19-21时",
        "21-23时",
      ],
      correctAnswer: correct,
    );
  }

  // ========== 地支关系题目重建函数 ==========

  static Question _buildLiuHeQuestion(String zhi) {
    final correct = getLiuHe(zhi);
    final diZhiNames = diZhi.map((item) => item["name"]!).toList();
    return Question(
      text: "谁和$zhi 六合？",
      options: diZhiNames,
      correctAnswer: correct,
    );
  }

  static Question _buildSanHeQuestion(String input) {
    // input 格式："亥卯未" (用逗号分隔的三个地支)
    final correct = input;
    // 这里需要生成其他三合组合作为干扰项
    final allSanHe = ["亥卯未", "寅午戌", "巳酉丑", "申子辰"];
    return Question(
      text: "以下哪组是三合？",
      options: allSanHe,
      correctAnswer: correct,
    );
  }

  static Question _buildSanXingQuestion(String input) {
    // input 格式："寅巳申" (用逗号分隔的三个地支)
    final correct = input;
    final allSanXing = ["寅巳申", "丑戌未", "子卯", "辰午酉亥"];
    return Question(
      text: "以下哪组是三刑？",
      options: allSanXing,
      correctAnswer: correct,
    );
  }

  static Question _buildZiXingQuestion(String zhi) {
    final correct = zhi;
    final ziXingOptions = ["辰", "午", "酉", "亥", "无自刑"];
    return Question(
      text: "以下哪个地支自刑？",
      options: ziXingOptions,
      correctAnswer: correct,
    );
  }

  static Question _buildLiuChongQuestion(String zhi) {
    // 六冲规则：相隔六位的地支相冲
    final diZhiCycle = [
      "子",
      "丑",
      "寅",
      "卯",
      "辰",
      "巳",
      "午",
      "未",
      "申",
      "酉",
      "戌",
      "亥",
    ];
    final index = diZhiCycle.indexOf(zhi);
    final correct = diZhiCycle[(index + 6) % 12];
    final diZhiNames = diZhi.map((item) => item["name"]!).toList();
    return Question(
      text: "谁和$zhi 六冲？",
      options: diZhiNames,
      correctAnswer: correct,
    );
  }

  static Question _buildLiuHaiQuestion(String zhi) {
    // 六害规则映射（暂时使用简化版本，实际应该查表）
    const liuHaiMap = {
      "子": "未",
      "丑": "午",
      "寅": "巳",
      "卯": "辰",
      "辰": "卯",
      "巳": "寅",
      "午": "丑",
      "未": "子",
      "申": "亥",
      "酉": "戌",
      "戌": "酉",
      "亥": "申",
    };
    final correct = liuHaiMap[zhi] ?? "未知";
    final diZhiNames = diZhi.map((item) => item["name"]!).toList();
    return Question(
      text: "谁和$zhi 六害？",
      options: diZhiNames,
      correctAnswer: correct,
    );
  }

  static Question _buildPoXiangQuestion(String zhi) {
    // 相破规则映射
    const poXiangMap = {
      "子": "酉",
      "丑": "辰",
      "寅": "亥",
      "卯": "午",
      "辰": "丑",
      "巳": "申",
      "午": "卯",
      "未": "戌",
      "申": "巳",
      "酉": "子",
      "戌": "未",
      "亥": "寅",
    };
    final correct = poXiangMap[zhi] ?? "未知";
    final diZhiNames = diZhi.map((item) => item["name"]!).toList();
    return Question(
      text: "谁和$zhi 相破？",
      options: diZhiNames,
      correctAnswer: correct,
    );
  }

  // ========== 地支指诀题目重建函数 ==========

  static Question _buildFingerForwardQuestion(String zhi) {
    final correct = getZhiFingerJoint(zhi);
    final joints = [
      "食指根",
      "食指中",
      "食指尖",
      "中指尖",
      "中指中",
      "中指根",
      "无名指根",
      "无名指中",
      "无名指尖",
      "小指尖",
      "小指中",
      "小指根",
    ];
    return Question(
      text: "$zhi 在手指的什么位置？",
      options: joints,
      correctAnswer: correct,
    );
  }

  static Question _buildFingerReverseQuestion(String joint) {
    final correct = getFingerJointZhi(joint);
    final diZhiNames = diZhi.map((item) => item["name"]!).toList();
    return Question(
      text: "$joint 对应哪个地支？",
      options: diZhiNames,
      correctAnswer: correct,
    );
  }

  // ========== 五行生克题目重建函数 ==========

  static Question _buildWuXingShengQuestion(String wuxing) {
    final correct = getWuXingSheng(wuxing);
    return Question(
      text: "$wuxing 生什么？",
      options: _wuxing,
      correctAnswer: correct,
    );
  }

  static Question _buildWuXingKeQuestion(String wuxing) {
    final correct = getWuXingKe(wuxing);
    return Question(
      text: "$wuxing 克什么？",
      options: _wuxing,
      correctAnswer: correct,
    );
  }

  // ========== 长生题目重建函数 ==========

  static Question _buildChangShengQuestion(String input) {
    // input 格式："木_子" (五行_地支)
    final parts = input.split('_');
    final wuxing = parts[0];
    final zhi = parts[1];
    final correct = getWuXingChangSheng(wuxing, zhi);
    final changshengStates = [
      "长生",
      "沐浴",
      "冠带",
      "临官",
      "帝旺",
      "衰",
      "病",
      "死",
      "墓",
      "绝",
      "胎",
      "养",
    ];
    return Question(
      text: "$wuxing 在 $zhi 处于什么状态？",
      options: changshengStates,
      correctAnswer: correct,
    );
  }

  // ========== 六十四卦题目重建函数 ==========

  /// 重建卦名到卦象题目
  /// input 格式：卦名（如"大有"）
  static Question _buildGuaToXiangQuestion(String guaName) {
    final correctXiang = getGuaXiang(guaName)!;

    // 生成错误选项：从其他卦象中随机选择
    final allXiang = getAllGuaXiang();
    final wrongOptions = List<String>.from(allXiang)..remove(correctXiang);
    wrongOptions.shuffle();

    // 组合选项：正确答案 + 3个错误选项
    final options = [correctXiang, ...wrongOptions.take(3)];
    options.shuffle();

    return Question(
      text: "卦「$guaName」的卦象是哪个？",
      options: options,
      correctAnswer: correctXiang,
    );
  }

  /// 重建卦象到卦名题目
  /// input 格式：卦象（如"火天"）
  static Question _buildXiangToGuaQuestion(String guaXiang) {
    final correctGua = getGuaName(guaXiang)!;

    // 生成错误选项：从其他卦名中随机选择
    final allGuaNames = getAllGuaNames();
    final wrongOptions = List<String>.from(allGuaNames)..remove(correctGua);
    wrongOptions.shuffle();

    // 组合选项：正确答案 + 3个错误选项
    final options = [correctGua, ...wrongOptions.take(3)];
    options.shuffle();

    return Question(
      text: "卦象「$guaXiang」对应的卦名是哪个？",
      options: options,
      correctAnswer: correctGua,
    );
  }

  /// 根据题目内容推断题目类型和输入参数
  /// 用于在答题时自动识别题目类型并记录错题
  /// @param question 题目对象
  /// @return [questionType, input] 或 null（无法识别）
  static Map<String, String>? inferQuestionTypeAndInput(Question question) {
    final text = question.text;

    // 尝试从题干中提取关键信息
    // 例如："甲 属于什么五行？" -> ["甲", "五行"]

    // 天干五行
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

    // 阴阳
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

    // 六合
    if (text.contains('六合？')) {
      final match = RegExp(r'谁和(.+) 六合？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_liuhe', 'input': match.group(1)!};
      }
    }

    // 六冲
    if (text.contains('六冲？')) {
      final match = RegExp(r'谁和(.+) 六冲？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_liuchong', 'input': match.group(1)!};
      }
    }

    // 六害
    if (text.contains('六害？')) {
      final match = RegExp(r'谁和(.+) 六害？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_liuhai', 'input': match.group(1)!};
      }
    }

    // 相破
    if (text.contains('相破？')) {
      final match = RegExp(r'谁和(.+) 相破？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'zhi_poxiang', 'input': match.group(1)!};
      }
    }

    // 方位
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

    // 季节
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

    // 指诀（正向）
    if (text.contains('在手指的什么位置？')) {
      for (final zhi in diZhi) {
        if (text.startsWith(zhi['name']!)) {
          return {'questionType': 'finger_forward', 'input': zhi['name']!};
        }
      }
    }

    // 五行生
    if (text.contains('生什么？')) {
      for (final wx in _wuxing) {
        if (text.startsWith(wx)) {
          return {'questionType': 'wuxing_sheng', 'input': wx};
        }
      }
    }

    // 五行克
    if (text.contains('克什么？')) {
      for (final wx in _wuxing) {
        if (text.startsWith(wx)) {
          return {'questionType': 'wuxing_ke', 'input': wx};
        }
      }
    }

    // 六十四卦：卦名到卦象
    if (text.contains('的卦象是哪个？')) {
      final match = RegExp(r'卦「(.+)」的卦象是哪个？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'gua_to_xiang', 'input': match.group(1)!};
      }
    }

    // 六十四卦：卦象到卦名
    if (text.contains('对应的卦名是哪个？')) {
      final match = RegExp(r'卦象「(.+)」对应的卦名是哪个？').firstMatch(text);
      if (match != null) {
        return {'questionType': 'xiang_to_gua', 'input': match.group(1)!};
      }
    }

    // TODO: 添加更多题型的识别逻辑

    return null; // 无法识别
  }
}
