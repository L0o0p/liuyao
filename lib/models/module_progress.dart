/// 模块学习进度数据模型
/// 用于追踪用户在某个学习模块中的进度和熟练度
class ModuleProgress {
  /// 模块唯一标识符（如 'tiangandizhi_wuxing'）
  final String moduleId;

  /// 是否已完成首轮学习（全覆盖）
  /// true: 已完成首轮，可以进入复习模式
  /// false: 尚未完成首轮，需要全覆盖学习
  bool firstRoundCompleted;

  /// 已学习过的知识点ID列表
  /// 用于追踪哪些知识点已经练习过
  /// 例如：["甲", "乙", "丙"] 表示已经练习过这些天干
  List<String> learnedItems;

  /// 每个知识点的熟练度映射
  /// key: 知识点ID（如 "甲"）
  /// value: 熟练度分数 (0-100)
  /// 分数越高表示越熟练，可用于决定题目出现频率
  Map<String, int> proficiency;

  /// 当前轮次的题目索引
  /// 用于记录用户在当前轮次中做到了第几题
  int currentQuestionIndex;

  /// 总共答对的题目数量（累计）
  int totalCorrectCount;

  /// 总共答错的题目数量（累计）
  int totalWrongCount;

  ModuleProgress({
    required this.moduleId,
    this.firstRoundCompleted = false,
    List<String>? learnedItems,
    Map<String, int>? proficiency,
    this.currentQuestionIndex = 0,
    this.totalCorrectCount = 0,
    this.totalWrongCount = 0,
  }) : learnedItems = learnedItems ?? [],
       proficiency = proficiency ?? {};

  /// 从 JSON 反序列化
  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['moduleId'] as String,
      firstRoundCompleted: json['firstRoundCompleted'] as bool? ?? false,
      learnedItems:
          (json['learnedItems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      proficiency:
          (json['proficiency'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      totalCorrectCount: json['totalCorrectCount'] as int? ?? 0,
      totalWrongCount: json['totalWrongCount'] as int? ?? 0,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'firstRoundCompleted': firstRoundCompleted,
      'learnedItems': learnedItems,
      'proficiency': proficiency,
      'currentQuestionIndex': currentQuestionIndex,
      'totalCorrectCount': totalCorrectCount,
      'totalWrongCount': totalWrongCount,
    };
  }

  /// 标记某个知识点已学习
  void markItemAsLearned(String itemId) {
    if (!learnedItems.contains(itemId)) {
      learnedItems.add(itemId);
    }
  }

  /// 更新某个知识点的熟练度
  /// @param itemId 知识点ID
  /// @param correct 本次是否答对
  void updateProficiency(String itemId, bool correct) {
    final currentScore = proficiency[itemId] ?? 50; // 默认从50分开始

    if (correct) {
      // 答对：增加熟练度，但不超过100
      proficiency[itemId] = (currentScore + 10).clamp(0, 100);
    } else {
      // 答错：降低熟练度，但不低于0
      proficiency[itemId] = (currentScore - 15).clamp(0, 100);
    }
  }

  /// 重置当前轮次进度（开始新一轮）
  void resetRound() {
    currentQuestionIndex = 0;
  }

  /// 获取需要加强练习的知识点列表
  /// 返回熟练度低于60分的知识点
  List<String> getWeakItems() {
    return proficiency.entries
        .where((entry) => entry.value < 60)
        .map((entry) => entry.key)
        .toList();
  }

  /// 计算总体正确率
  double get accuracy {
    final total = totalCorrectCount + totalWrongCount;
    if (total == 0) return 0.0;
    return totalCorrectCount / total;
  }
}

