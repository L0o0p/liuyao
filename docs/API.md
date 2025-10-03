# API 文档

本文档描述了六爻学习 App 中核心类的公共 API 接口。

## 目录

- [数据模型 (Models)](#数据模型)
  - [Question](#question)
  - [ModuleProgress](#moduleprogress)
- [服务层 (Services)](#服务层)
  - [RoundManager](#roundmanager)
  - [StorageService](#storageservice)
  - [QuestionFactory](#questionfactory)
  - [Questions](#questions)
  - [RuleFunctions](#rulefunctions)

---

## 数据模型

### Question

题目数据模型。

```dart
class Question {
  final String text;              // 题目文本
  final List<String> options;     // 选项列表
  final String correctAnswer;     // 正确答案
}
```

#### 构造函数

```dart
Question({
  required String text,
  required List<String> options,
  required String correctAnswer,
})
```

#### 示例

```dart
final question = Question(
  text: "甲 属于什么五行？",
  options: ["木", "火", "土", "金", "水"],
  correctAnswer: "木",
);
```

---

### ModuleProgress

模块学习进度数据模型。

```dart
class ModuleProgress {
  final String moduleId;                    // 模块ID
  bool firstRoundCompleted;                 // 是否完成首轮
  List<String> learnedItems;                // 已学习知识点列表
  Map<String, int> proficiency;             // 熟练度映射
  int currentQuestionIndex;                 // 当前题目索引
  int totalCorrectCount;                    // 累计答对数
  int totalWrongCount;                      // 累计答错数
}
```

#### 构造函数

```dart
ModuleProgress({
  required String moduleId,
  bool firstRoundCompleted = false,
  List<String>? learnedItems,
  Map<String, int>? proficiency,
  int currentQuestionIndex = 0,
  int totalCorrectCount = 0,
  int totalWrongCount = 0,
})
```

#### 方法

##### markItemAsLearned

标记某个知识点已学习。

```dart
void markItemAsLearned(String itemId)
```

**参数：**
- `itemId`: 知识点ID（如 "甲"）

**示例：**
```dart
progress.markItemAsLearned("甲");
```

---

##### updateProficiency

更新某个知识点的熟练度。

```dart
void updateProficiency(String itemId, bool correct)
```

**参数：**
- `itemId`: 知识点ID
- `correct`: 本次是否答对

**逻辑：**
- 答对：熟练度 +10（上限100）
- 答错：熟练度 -15（下限0）

**示例：**
```dart
progress.updateProficiency("甲", true);  // 答对
progress.updateProficiency("乙", false); // 答错
```

---

##### resetRound

重置当前轮次进度（开始新一轮）。

```dart
void resetRound()
```

**示例：**
```dart
progress.resetRound();
```

---

##### getWeakItems

获取需要加强练习的知识点列表（熟练度 < 60）。

```dart
List<String> getWeakItems()
```

**返回：** 熟练度低于60分的知识点ID列表

**示例：**
```dart
final weakItems = progress.getWeakItems();
print("需要加强: $weakItems");
```

---

##### accuracy

计算总体正确率。

```dart
double get accuracy
```

**返回：** 0.0 - 1.0 之间的正确率

**示例：**
```dart
final rate = progress.accuracy;
print("正确率: ${(rate * 100).toStringAsFixed(1)}%");
```

---

##### toJson / fromJson

序列化和反序列化。

```dart
Map<String, dynamic> toJson()
factory ModuleProgress.fromJson(Map<String, dynamic> json)
```

**示例：**
```dart
// 序列化
final json = progress.toJson();
final jsonString = jsonEncode(json);

// 反序列化
final decoded = jsonDecode(jsonString);
final progress = ModuleProgress.fromJson(decoded);
```

---

## 服务层

### RoundManager

题表管理器，负责生成题目和管理学习进度。

```dart
class RoundManager {
  RoundManager(String moduleId)
}
```

#### 构造函数

```dart
RoundManager(String moduleId)
```

**参数：**
- `moduleId`: 模块ID（如 'tiangandizhi_wuxing'）

---

#### 方法

##### initialize

初始化管理器，加载进度并生成题目。**必须在使用前调用。**

```dart
Future<void> initialize()
```

**示例：**
```dart
final manager = RoundManager('tiangandizhi_wuxing');
await manager.initialize();
```

---

##### questions

获取当前轮次的所有题目。

```dart
List<Question> get questions
```

**示例：**
```dart
final allQuestions = manager.questions;
print("本轮共 ${allQuestions.length} 题");
```

---

##### currentIndex

获取当前题目索引。

```dart
int get currentIndex
```

---

##### isFirstRoundCompleted

是否完成首轮学习。

```dart
bool get isFirstRoundCompleted
```

---

##### progress

获取进度对象（用于展示统计信息）。

```dart
ModuleProgress get progress
```

**示例：**
```dart
final accuracy = manager.progress.accuracy;
final correct = manager.progress.totalCorrectCount;
```

---

##### submitAnswer

提交答案并更新进度。

```dart
Future<void> submitAnswer(int questionIndex, bool isCorrect)
```

**参数：**
- `questionIndex`: 题目索引
- `isCorrect`: 是否答对

**示例：**
```dart
await manager.submitAnswer(0, true);  // 第一题答对
await manager.submitAnswer(1, false); // 第二题答错
```

---

##### completeRound

完成当前轮次。如果是首轮，标记为已完成；否则开始新一轮。

```dart
Future<void> completeRound()
```

**示例：**
```dart
await manager.completeRound();
```

---

##### getNextQuestion

获取下一题。

```dart
Question? getNextQuestion()
```

**返回：** 下一题的 Question 对象，如果没有更多题目则返回 null

**示例：**
```dart
final next = manager.getNextQuestion();
if (next != null) {
  // 显示题目
} else {
  // 本轮已完成
}
```

---

##### reset

重置模块进度（重新开始）。

```dart
Future<void> reset()
```

**示例：**
```dart
await manager.reset();
```

---

### StorageService

本地存储服务，负责进度的持久化。

#### 静态方法

##### saveProgress

保存模块进度到本地。

```dart
static Future<void> saveProgress(ModuleProgress progress)
```

**参数：**
- `progress`: 要保存的进度对象

**示例：**
```dart
await StorageService.saveProgress(progress);
```

---

##### loadProgress

从本地加载模块进度。

```dart
static Future<ModuleProgress> loadProgress(String moduleId)
```

**参数：**
- `moduleId`: 模块ID

**返回：** 进度对象，如果不存在则返回新创建的默认进度

**示例：**
```dart
final progress = await StorageService.loadProgress('tiangandizhi_wuxing');
```

---

##### clearProgress

清除某个模块的进度（重置学习）。

```dart
static Future<void> clearProgress(String moduleId)
```

**参数：**
- `moduleId`: 模块ID

**示例：**
```dart
await StorageService.clearProgress('tiangandizhi_wuxing');
```

---

##### clearAllProgress

清除所有模块的进度。

```dart
static Future<void> clearAllProgress()
```

**示例：**
```dart
await StorageService.clearAllProgress();
```

---

##### isFirstTime

检查模块是否是首次学习。

```dart
static Future<bool> isFirstTime(String moduleId)
```

**参数：**
- `moduleId`: 模块ID

**返回：** true 表示首次学习，false 表示已有学习记录

**示例：**
```dart
final isFirst = await StorageService.isFirstTime('tiangandizhi_wuxing');
if (isFirst) {
  print("欢迎首次学习！");
}
```

---

### QuestionFactory

题目工厂，根据模块类型生成题目。

#### 静态方法

##### generateTianGanDizhiQuestion

生成天干地支基础题目（五行相关）。

```dart
static Question generateTianGanDizhiQuestion()
```

**返回：** 随机生成的天干或地支五行题目

---

##### generateTianGanDizhiYinYangQuestion

生成天干地支阴阳题目。

```dart
static Question generateTianGanDizhiYinYangQuestion()
```

---

##### generateDirectionQuestion

生成方位题目。

```dart
static Question generateDirectionQuestion()
```

---

##### generateTimeQuestion

生成时间题目。

```dart
static Question generateTimeQuestion()
```

---

##### generateFingerJointQuestion

生成地支指诀题目。

```dart
static Question generateFingerJointQuestion()
```

---

##### generateXingChongHeChongQuestion

生成刑冲合害题目。

```dart
static Question generateXingChongHeChongQuestion()
```

---

##### generateChangShengQuestion

生成十二长生题目。

```dart
static Question generateChangShengQuestion()
```

---

### Questions

具体题目生成器集合。

#### 静态方法

##### 天干地支基础

```dart
static Question generateGanWuXingQuestion()      // 天干五行
static Question generateZhiWuXingQuestion()      // 地支五行
static Question generateGanYinYangQuestion()     // 天干阴阳
static Question generateZhiYinYangQuestion()     // 地支阴阳
```

##### 方位时间

```dart
static Question generateGanDirectionQuestion()   // 天干方位
static Question generateZhiDirectionQuestion()   // 地支方位
static Question generateGanSeasonQuestion()      // 天干季节
static Question generateZhiSeasonQuestion()      // 地支季节
static Question generateGanMonthQuestion()       // 天干月份
static Question generateZhiMonthQuestion()       // 地支月份
static Question generateZhiTimeQuestion()        // 地支时辰
static Question generateZhiHourQuestion()        // 地支时间段
```

##### 刑冲合害

```dart
static Question generateLiuHeQuestion()          // 六合
static Question generateSanHeQuestion()          // 三合
static Question generateSanXingQuestion()        // 三刑
static Question generateZiXingQuestion()         // 自刑
```

##### 指诀和长生

```dart
static Question generateFingerJointForwardQuestion()   // 正向指诀
static Question generateFingerJointReverseQuestion()   // 反向指诀
static Question generateChangShengQuestion()           // 十二长生
```

##### 五行生克

```dart
static Question generateWuXingShengQuestion()    // 五行生
static Question generateWuXingKeQuestion()       // 五行克
```

---

### RuleFunctions

六爻规则查询函数。

#### 天干相关

```dart
String getGanWuXing(String gan)        // 查询天干五行
String getGanYinYang(String gan)       // 查询天干阴阳
String getGanDirection(String gan)     // 查询天干方位
String getGanSeason(String gan)        // 查询天干季节
String getGanMonth(String gan)         // 查询天干月份
String getGanTime(String gan)          // 查询天干时辰
```

**示例：**
```dart
print(getGanWuXing("甲"));     // "木"
print(getGanYinYang("乙"));    // "阴"
print(getGanDirection("丙"));  // "南"
```

---

#### 地支相关

```dart
String getZhiWuXing(String zhi)        // 查询地支五行
String getZhiYinYang(String zhi)       // 查询地支阴阳
String getZhiDirection(String zhi)     // 查询地支方位
String getZhiSeason(String zhi)        // 查询地支季节
String getZhiMonth(String zhi)         // 查询地支月份
String getZhiTime(String zhi)          // 查询地支时辰
String getZhiHour(String zhi)          // 查询地支时间段
String getZhiFingerJoint(String zhi)   // 查询地支指诀位置
```

**示例：**
```dart
print(getZhiWuXing("子"));           // "水"
print(getZhiFingerJoint("寅"));      // "无名指根部"
```

---

#### 地支关系

```dart
String getLiuHe(String zhi)                                    // 查询六合
String getWuXingChangSheng(String riZhi, String yaoZhi)       // 查询十二长生
```

**示例：**
```dart
print(getLiuHe("子"));                      // "丑"
print(getWuXingChangSheng("子", "申"));     // "长生"
```

---

## 模块ID 规范

| 模块ID | 说明 |
|--------|------|
| `tiangandizhi_wuxing` | 天干地支五行 |
| `tiangandizhi_yinyang` | 天干地支阴阳 |
| `tiangandizhi_direction` | 方位对应 |
| `tiangandizhi_time` | 时间对应 |
| `tiangandizhi_shengke` | 五行生克 |
| `tiangandizhi_comprehensive` | 天干地支综合 |
| `wuxing` | 十二支指诀 |
| `hechong` | 六合三合六冲 |
| `shierchangsheng` | 十二长生 |
| `comprehensive` | 综合练习 |

---

## 使用示例

### 完整学习流程

```dart
// 1. 创建 RoundManager
final manager = RoundManager('tiangandizhi_wuxing');

// 2. 初始化
await manager.initialize();

// 3. 获取题目
final questions = manager.questions;
print("本轮共 ${questions.length} 题");

// 4. 用户答题
for (int i = 0; i < questions.length; i++) {
  final question = questions[i];
  
  // 显示题目
  print(question.text);
  
  // 用户选择答案
  final userAnswer = getUserAnswer(); // 假设这个函数获取用户选择
  
  // 判断对错
  final isCorrect = userAnswer == question.correctAnswer;
  
  // 提交答案
  await manager.submitAnswer(i, isCorrect);
}

// 5. 完成本轮
await manager.completeRound();

// 6. 显示统计
final accuracy = manager.progress.accuracy;
print("正确率: ${(accuracy * 100).toStringAsFixed(1)}%");
```

---

### 查询进度信息

```dart
// 加载进度
final progress = await StorageService.loadProgress('tiangandizhi_wuxing');

// 查看基本信息
print("是否完成首轮: ${progress.firstRoundCompleted}");
print("答题总数: ${progress.totalCorrectCount + progress.totalWrongCount}");
print("正确率: ${(progress.accuracy * 100).toStringAsFixed(1)}%");

// 查看薄弱点
final weakItems = progress.getWeakItems();
print("需要加强的知识点: $weakItems");

// 查看熟练度
for (final entry in progress.proficiency.entries) {
  print("${entry.key}: ${entry.value}分");
}
```

---

### 重置进度

```dart
// 重置单个模块
await StorageService.clearProgress('tiangandizhi_wuxing');

// 重置所有模块
await StorageService.clearAllProgress();
```

---

## 错误处理

### 常见错误

#### 1. 未初始化就使用 RoundManager

```dart
// ❌ 错误
final manager = RoundManager('xxx');
final questions = manager.questions; // 此时 questions 为空

// ✅ 正确
final manager = RoundManager('xxx');
await manager.initialize();
final questions = manager.questions;
```

#### 2. 使用不存在的模块ID

```dart
// ❌ 错误
final manager = RoundManager('invalid_module');
await manager.initialize(); // 会生成默认题目

// ✅ 正确：使用规范的模块ID
final manager = RoundManager('tiangandizhi_wuxing');
```

#### 3. JSON 解析失败

```dart
// StorageService 内部已处理
try {
  final json = jsonDecode(jsonString);
  return ModuleProgress.fromJson(json);
} catch (e) {
  // 解析失败，返回默认进度
  return ModuleProgress(moduleId: moduleId);
}
```

---

## 最佳实践

### 1. 使用 RoundManager 而非直接调用 Questions

```dart
// ❌ 不推荐
final question = Questions.generateGanWuXingQuestion();

// ✅ 推荐
final manager = RoundManager('tiangandizhi_wuxing');
await manager.initialize();
final questions = manager.questions;
```

**原因：** RoundManager 会自动管理进度和学习模式。

---

### 2. 及时保存进度

```dart
// ✅ 每次答题后保存
await manager.submitAnswer(index, isCorrect);
```

**原因：** 防止用户退出后丢失进度。

---

### 3. 使用 mounted 检查

```dart
// ✅ 在异步操作后检查 widget 是否还在
await manager.completeRound();
if (!mounted) return;
showDialog(...);
```

**原因：** 防止在 widget dispose 后调用 setState。

---

## 版本历史

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| v1.0 | 2025-10-03 | 初始版本 |

---

**维护者**: LoopShen  
**最后更新**: 2025-10-03

