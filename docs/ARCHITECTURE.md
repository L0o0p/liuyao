# 架构设计文档

## 总览

本文档详细描述了六爻学习 App 的架构设计、核心模块实现原理以及设计决策的思考过程。

## 设计理念

### 核心问题

在开始设计之前，我们需要解决一个核心问题：

> **如何在随机生成题目的同时，保证覆盖全范围？**

这个问题看似简单，实际上涉及到学习系统的根本设计。

### 两种常见方案的对比

#### 方案一：纯随机生成
```dart
// 每次都随机选择一个天干生成题目
Question generate() {
  final gan = tianGan[Random().nextInt(10)];
  return createQuestion(gan);
}
```

**优点**：
- 题目多样，不容易背答案
- 实现简单

**缺点**：
- 有些知识点可能一直没抽到
- 用户覆盖不完整，学习效果无法保证
- 可能导致挫败感（一直答不到某些题）

#### 方案二：预烘焙题表
```dart
// 一次性生成所有题目，顺序执行
List<Question> generateAll() {
  return tianGan.map((gan) => createQuestion(gan)).toList();
}
```

**优点**：
- 能确保"循环一遍，所有题都被考过"
- 学习进度可预测

**缺点**：
- 题目可预测，用户可能背答案而非理解
- 缺乏完全的随机感
- 重复做题时会感到枯燥

### 最终方案：混合模式 ✅

我们采用了**分层学习策略**，结合两种方案的优点：

```
第一层：课本模式（首轮学习）
├── 目标：打好基础，确保全覆盖
├── 策略：生成全覆盖题表，但打乱顺序
└── 效果：每个知识点至少出现一次

第二层：练习册模式（复习阶段）
├── 目标：巩固薄弱点，保持熟练度
├── 策略：60% 薄弱点 + 40% 随机
└── 效果：针对性强化，避免遗忘
```

## 核心模块设计

### 1. RoundManager（题表管理器）

这是整个学习系统的大脑，负责：
1. 判断学习模式（首轮/复习）
2. 生成题目列表
3. 管理学习进度
4. 记录答题结果

#### 状态机设计

```
┌─────────────┐
│  未开始学习  │
└──────┬──────┘
       │ initialize()
       ↓
┌─────────────────┐
│  首轮学习模式    │ ← firstRoundCompleted = false
│  (全覆盖题表)    │
└──────┬──────────┘
       │ completeRound()
       ↓
┌─────────────────┐
│   复习模式       │ ← firstRoundCompleted = true
│  (智能出题)      │
└──────┬──────────┘
       │ reset()
       ↓
┌─────────────┐
│  未开始学习  │
└─────────────┘
```

#### 关键方法

**initialize()**
```dart
Future<void> initialize() async {
  // 1. 从本地加载进度
  _progress = await StorageService.loadProgress(moduleId);
  
  // 2. 根据进度判断模式
  if (!_progress.firstRoundCompleted) {
    // 首次学习：生成全覆盖题表
    _currentRound = _generateFullCoverageRound();
  } else {
    // 复习模式：生成智能题表
    _currentRound = _generateReviewRound();
  }
}
```

**_generateFullCoverageRound()**
```dart
List<Question> _generateFullCoverageRound() {
  // 设计原理：
  // 1. 列出所有需要学习的知识点
  // 2. 为每个知识点生成一道题
  // 3. 打乱顺序（避免用户记住顺序而非内容）
  
  switch (moduleId) {
    case 'tiangandizhi_wuxing':
      // 天干10个 + 地支12个 = 22题
      final questions = [];
      
      // 天干部分
      final gans = ["甲","乙","丙","丁","戊","己","庚","辛","壬","癸"];
      gans.shuffle(); // 关键：打乱顺序
      for (final gan in gans) {
        questions.add(_createGanWuXingQuestion(gan));
      }
      
      // 地支部分
      final zhis = ["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"];
      zhis.shuffle();
      for (final zhi in zhis) {
        questions.add(_createZhiWuXingQuestion(zhi));
      }
      
      return questions;
  }
}
```

**_generateReviewRound()**
```dart
List<Question> _generateReviewRound() {
  // 设计原理（间隔重复算法的简化版）：
  // 1. 识别薄弱知识点（熟练度 < 60）
  // 2. 大部分题目考薄弱点（60%）
  // 3. 少部分题目随机（40%），保持多样性
  
  final weakItems = _progress.getWeakItems(); // 熟练度 < 60
  final totalQuestions = 20;
  
  // 计算题目分配
  final weakCount = (totalQuestions * 0.6).round(); // 12题
  final randomCount = totalQuestions - weakCount;   // 8题
  
  final questions = [];
  
  // 生成薄弱点题目
  for (int i = 0; i < weakCount && weakItems.isNotEmpty; i++) {
    final item = weakItems[Random().nextInt(weakItems.length)];
    questions.add(_createQuestionForItem(item));
  }
  
  // 生成随机题目（保持新鲜感）
  for (int i = 0; i < randomCount; i++) {
    questions.add(_generateRandomQuestionForModule());
  }
  
  // 打乱顺序（用户不知道哪些是薄弱点）
  questions.shuffle();
  return questions;
}
```

### 2. ModuleProgress（进度模型）

存储和管理用户的学习进度。

#### 数据结构设计思考

```dart
class ModuleProgress {
  // Q: 为什么需要 moduleId？
  // A: 支持多模块独立进度追踪
  String moduleId;
  
  // Q: firstRoundCompleted 的作用？
  // A: 关键标志位，决定使用哪种出题策略
  bool firstRoundCompleted;
  
  // Q: 为什么要记录 learnedItems？
  // A: 可以展示"已学习 X/Y 个知识点"，增强成就感
  List<String> learnedItems;
  
  // Q: proficiency 如何更新？
  // A: 答对 +10 分，答错 -15 分（错误的惩罚更大）
  Map<String, int> proficiency;
  
  // Q: 为什么要记录 currentQuestionIndex？
  // A: 支持中断后继续（用户可能随时退出）
  int currentQuestionIndex;
  
  // Q: 为什么分别记录对错数量？
  // A: 可以计算正确率，展示学习效果
  int totalCorrectCount;
  int totalWrongCount;
}
```

#### 熟练度算法

```dart
void updateProficiency(String itemId, bool correct) {
  final currentScore = proficiency[itemId] ?? 50; // 初始值50（中等水平）
  
  if (correct) {
    // 答对：增加10分
    // 原理：正反馈，但不能一次性涨太多（防止虚高）
    proficiency[itemId] = (currentScore + 10).clamp(0, 100);
  } else {
    // 答错：减少15分
    // 原理：负反馈更重（一次错误抵消1.5次正确）
    //       体现"错误记忆更深刻"的心理学原理
    proficiency[itemId] = (currentScore - 15).clamp(0, 100);
  }
}
```

**为什么错误惩罚更大？**

心理学研究表明，人对错误的记忆更深刻。在学习系统中：
- 如果答错扣分太少，用户可能轻视错误
- 如果扣分是答对的1.5倍，用户会更重视错误，认真对待每一题

**为什么初始值是50？**

- 0分：假设用户完全不会（太悲观）
- 100分：假设用户已掌握（太乐观）
- 50分：中立假设，让数据说话

### 3. StorageService（存储服务）

#### 设计决策：为什么选择 SharedPreferences？

**考虑过的方案：**

| 方案 | 优点 | 缺点 | 是否采用 |
|------|------|------|---------|
| SharedPreferences | 轻量、简单、跨平台 | 只能存小数据 | ✅ 采用 |
| SQLite | 结构化查询、关系型 | 重量级、需要迁移 | ❌ 过度设计 |
| Hive | 高性能、NoSQL | 需要额外依赖 | ❌ 增加复杂度 |
| Cloud Firestore | 云端同步、多端 | 需要网络、成本 | ❌ 未来扩展 |

**最终选择 SharedPreferences 的原因：**
1. 数据量小（每个模块进度 < 10KB）
2. 访问频繁（每次答题都要保存）
3. 无需复杂查询
4. 跨平台一致性好

#### 存储格式

```dart
// Key 格式
"module_progress_{moduleId}"

// Value 格式（JSON）
{
  "moduleId": "tiangandizhi_wuxing",
  "firstRoundCompleted": false,
  "learnedItems": ["甲", "乙", "丙"],
  "proficiency": {
    "甲": 65,
    "乙": 55,
    "丙": 70
  },
  "currentQuestionIndex": 3,
  "totalCorrectCount": 15,
  "totalWrongCount": 5
}
```

### 4. QuestionFactory（题目工厂）

#### 设计模式：工厂模式

为什么使用工厂模式？

```dart
// ❌ 不好的设计：在UI层直接生成题目
class StudyScreen extends StatelessWidget {
  void loadQuestions() {
    if (moduleType == 'wuxing') {
      questions = [/* 生成五行题目 */];
    } else if (moduleType == 'hechong') {
      questions = [/* 生成合冲题目 */];
    }
    // ... 越来越多的 if-else
  }
}

// ✅ 好的设计：使用工厂模式
class QuestionFactory {
  static Question generateForModule(String moduleType) {
    switch (moduleType) {
      case 'wuxing': return _generateWuXingQuestion();
      case 'hechong': return _generateHeChongQuestion();
      // ...
    }
  }
}
```

**优势：**
1. UI层不关心题目如何生成（单一职责）
2. 新增题型只需修改工厂（开闭原则）
3. 可以统一处理题目配置（DRY原则）

## 数据流详解

### 学习流程完整数据流

```
1. 用户进入学习模块
   ↓
2. StudyModuleScreen.initState()
   ↓
3. RoundManager.initialize()
   ├── StorageService.loadProgress(moduleId)
   │   └── SharedPreferences.getString('module_progress_xxx')
   ├── 判断 firstRoundCompleted
   └── 生成题目列表
   ↓
4. 用户答题
   ↓
5. FlipCard.onAnswerSelected()
   ↓
6. RoundManager.submitAnswer(index, isCorrect)
   ├── 更新 totalCorrectCount / totalWrongCount
   ├── 更新 proficiency[itemId]
   └── StorageService.saveProgress(progress)
       └── SharedPreferences.setString(...)
   ↓
7. 判断是否完成本轮
   ├── 未完成：继续答题（返回步骤4）
   └── 完成：RoundManager.completeRound()
       ├── 标记 firstRoundCompleted = true
       ├── 保存进度
       └── 显示完成弹窗
```

### 进度页数据流

```
1. 用户打开进度页
   ↓
2. ProgressScreen.initState()
   ↓
3. _loadAllProgress()
   ├── 遍历所有模块配置
   └── 并行调用 StorageService.loadProgress()
   ↓
4. 更新 UI
   ├── _calculateOverallStats() 计算总体统计
   ├── _buildOverallStatsCard() 渲染统计卡片
   └── _buildModuleProgressCard() 渲染各模块卡片
```

## 性能优化

### 1. 异步加载优化

```dart
// ❌ 串行加载（慢）
Future<void> loadAllProgress() async {
  for (final module in modules) {
    final progress = await loadProgress(module.id);
    progressMap[module.id] = progress;
  }
}

// ✅ 并行加载（快）
Future<void> loadAllProgress() async {
  final futures = modules.map((m) => loadProgress(m.id));
  final results = await Future.wait(futures);
  // ... 处理结果
}
```

### 2. 题目生成优化

```dart
// 避免每次都重新计算
class Questions {
  // ❌ 每次调用都创建新的列表
  static List<String> get wuxing => ["木", "火", "土", "金", "水"];
  
  // ✅ 使用常量
  static const _wuxing = ["木", "火", "土", "金", "水"];
}
```

### 3. UI 刷新优化

```dart
// 使用 setState 时，尽量缩小刷新范围
setState(() {
  _currentPageIndex = newIndex; // 只更新必要的变量
});
```

## 可扩展性设计

### 1. 新增学习模块

只需三步：

**Step 1: 定义数据**
```dart
// data/new_module_data.dart
const newModuleData = [...];
```

**Step 2: 添加题目生成器**
```dart
// services/questions.dart
static Question generateNewModuleQuestion() {
  // 实现题目生成逻辑
}
```

**Step 3: 在 RoundManager 中添加支持**
```dart
// services/round_manager.dart
case 'new_module':
  questions = _generateNewModuleQuestions();
```

### 2. 新增题型

在 `Questions` 类中添加新的生成方法即可：

```dart
static Question generateNewTypeQuestion() {
  return Question(
    text: "新题型的问题？",
    options: ["选项1", "选项2", "选项3", "选项4"],
    correctAnswer: "选项1",
  );
}
```

### 3. 更换存储方案

由于使用了 `StorageService` 抽象层，更换存储方案只需修改该类：

```dart
// 从 SharedPreferences 切换到 Hive
class StorageService {
  static Future<void> saveProgress(ModuleProgress progress) async {
    // 原来：SharedPreferences.setString(...)
    // 现在：HiveBox.put(...)
  }
}
```

## 设计权衡

### 1. 为什么不用 Provider/Bloc？

**考虑：**
- 项目规模较小
- 状态管理不复杂（大多是页面级状态）
- 学习曲线

**决策：** 使用 StatefulWidget 足够，保持简单

### 2. 为什么不做服务端？

**考虑：**
- 增加开发和维护成本
- 用户隐私（学习数据敏感）
- 离线使用需求

**决策：** 纯本地应用，未来可选云端同步

### 3. 为什么熟练度阈值是 60？

**尝试过：**
- 50：太容易达到，薄弱点太少
- 70：太难达到，一直在练薄弱点
- 60：平衡点，用户体验最佳

**决策：** 60分作为"及格线"，符合直觉

## 测试策略

### 单元测试重点

```dart
// 测试熟练度更新逻辑
test('答对增加10分', () {
  final progress = ModuleProgress(moduleId: 'test');
  progress.proficiency['甲'] = 50;
  progress.updateProficiency('甲', true);
  expect(progress.proficiency['甲'], 60);
});

// 测试边界条件
test('熟练度不超过100', () {
  final progress = ModuleProgress(moduleId: 'test');
  progress.proficiency['甲'] = 95;
  progress.updateProficiency('甲', true);
  expect(progress.proficiency['甲'], 100); // 不是105
});
```

### 集成测试重点

```dart
// 测试完整学习流程
testWidgets('完成首轮学习后进入复习模式', (tester) async {
  // 1. 进入模块
  // 2. 完成所有题目
  // 3. 验证 firstRoundCompleted = true
  // 4. 重新进入
  // 5. 验证题目数量和类型
});
```

## 后续优化方向

### 短期
1. 添加题目缓存（避免重复生成）
2. 实现答题动画优化
3. 添加音效和震动反馈

### 中期
1. 引入机器学习预测用户薄弱点
2. 实现自适应难度调整
3. 添加知识图谱关联

### 长期
1. 多人PK模式
2. 社区分享错题
3. AI 个性化学习路径推荐

---

**文档版本**: v1.0  
**最后更新**: 2025-10-03  
**维护者**: LoopShen

