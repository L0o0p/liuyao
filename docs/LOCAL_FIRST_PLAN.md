# 本地优先改造执行文档

## 背景与决策

当前的 CloudKit 同步存在几个实现缺陷，导致卸载重装后学习进度丢失：

- 登录后只上传，不从云端拉取。
- 云端只存了正确率和答对、答错数。
- 每次用新建的 `CKRecord` 保存固定 ID，重复写入会被 CloudKit 拒绝。
- `isCloudKitAvailable()` 会上传测试数据，覆盖真实记录。

暂不确定未来是只做 iOS（CloudKit 加 Game Center），还是同时做 Android（阿里云自建服务）。因此本阶段的决策是：

1. **应用改为纯本地运行**，移除 CloudKit 和 Apple 登录。
2. **把同步逻辑抽到一个可替换的接口后面**，本阶段只提供空实现。
3. **把数据模型整理成适合同步的形态**：每条数据都有稳定的键和 `updatedAt`。
4. **补齐题目的知识点标识**，让熟练度真正生效。这是之后做学习曲线和间隔重复的前提。

以后接入任一云端时，只需新增一个同步实现，首次同步把本地数据整体上传即可，不需要迁移云端数据。

## 非目标

- 本阶段不接入任何云端，不做账号体系。
- 不改学习界面和交互流程。
- 不引入 SQLite，继续使用 SharedPreferences。

---

## 第 1 步：移除 CloudKit 与 Apple 登录

### 删除的文件

- `lib/services/cloudkit_storage_service.dart`
- `lib/services/apple_auth_service.dart`
- `lib/widgets/apple_sign_in_button.dart`，其中包含 `AppleSignInButton`、`CloudSyncIndicator`、`SyncButton`
- `lib/examples/apple_login_example.dart`
- `ios/Runner/CloudKitPlugin.swift`，同时从 Xcode 工程里移除引用
- 根目录文档：`CLOUDKIT_SETUP.md`、`CLOUDKIT_SETUP_GUIDE.md`、`APPLE_LOGIN_CLOUDKIT_GUIDE.md`

### 修改的文件

- `ios/Runner/AppDelegate.swift`：删除 `CloudKitPlugin.register(...)` 这一行。
- `ios/Runner/Runner.entitlements`：删除 `com.apple.developer.applesignin`、`com.apple.developer.icloud-container-identifiers` 和 `com.apple.developer.icloud-services`。
- `ios/Runner.xcodeproj/project.pbxproj`：移除 `CloudKitPlugin.swift` 的文件引用，以及 Signing & Capabilities 里的 iCloud 和 Sign in with Apple 两项能力。建议在 Xcode 里操作。
- `pubspec.yaml`：删除 `sign_in_with_apple` 依赖，然后执行 `flutter pub get` 和 `cd ios && pod install`。
- `lib/services/storage_service.dart`：删除 `initialize()` 里的登录和 CloudKit 检测，以及 `enableCloudSync`、`syncToCloud`、`syncFromCloud`、`getLastSyncTime`、`signOut`，还有所有 `isCloudSyncEnabled` 分支。
- `lib/screens/progress_screen.dart`：删除云端同步卡片，包括登录按钮、同步按钮和"上次同步时间"。
- `lib/main.dart`：如果 `StorageService.initialize()` 已经没有内容，就一并删掉这次调用。

### 验收

- `rg -i "cloudkit|apple_auth|sign_in_with_apple|SyncButton" lib ios/Runner` 没有结果。
- `flutter analyze` 没有新增问题，iOS 能正常构建和运行。
- 答题后，进度页和错题本照常显示；杀掉进程重开后，数据仍然在。

---

## 第 2 步：给题目补上知识点标识

### 问题

`Question` 目前只有 `text`、`options` 和 `correctAnswer`，答题时不知道考的是哪个知识点，因此：

- `RoundManager.submitAnswer` 里更新熟练度的代码被注释掉，`proficiency` 从来不会变化。
- `_createGanWuXingQuestion(gan)` 等函数忽略传入的参数，实际仍是随机出题。所以首轮的"全覆盖"并不成立。
- 错题记录要靠 `QuestionReconstructor.inferQuestionTypeAndInput` 从题干反推题型。

### 改动

1. `lib/models/question.dart`：新增 `questionType` 和 `input` 两个字段，并写入 `toJson` 和 `fromJson`。旧数据没有这两个字段，所以 `fromJson` 读取时要允许缺失。
   - 题型取值和 `QuestionReconstructor.reconstructFromRecord` 的 `switch` 分支保持一致，比如 `gan_wuxing`、`zhi_liuhe`。
   - 新增计算属性 `itemKey => '${questionType}:$input'`，作为知识点的唯一键。
2. `lib/services/questions.dart`：每个生成函数都支持传入指定的输入（如 `generateGanWuXingQuestion({String? gan})`），并在返回的 `Question` 里带上题型和输入。
3. `lib/services/round_manager.dart`：
   - 让 `_create*Question(item)` 把参数真正传下去。
   - 在 `submitAnswer` 里调用 `_progress.updateProficiency(question.itemKey, isCorrect)` 和 `_progress.markItemAsLearned(question.itemKey)`。
   - `_createQuestionForItem` 改成解析 `itemKey`，按题型和输入出题，不再只判断是天干还是地支。
4. `lib/screens/study_module_screen.dart`：记录错题时直接使用 `question.questionType` 和 `question.input`。旧题表没有这两个字段，这时才退回用 `inferQuestionTypeAndInput` 反推。

`proficiency` 的键会从原来设想的 `"甲"` 变成 `"gan_wuxing:甲"`。旧数据里这个映射一直为空，不需要迁移。

### 验收

- 首轮全覆盖：比如 `tiangandizhi_wuxing` 的 22 道题，恰好覆盖 10 个天干和 12 个地支，没有重复。为此在 `test/` 下补一个单元测试。
- 答题后，`proficiency` 里对应的键按"答对加 10、答错减 15"变化。
- 复习模式下，薄弱知识点的题目确实出自这些知识点。

---

## 第 3 步：把本地数据整理成适合同步的形态

### 原则

- 每条可同步的数据都有一个稳定的键，并且是一份完整、可以整体覆盖的 JSON。
- 每条数据都带 `updatedAt`，以毫秒时间戳记录。合并规则统一为时间较新者胜。
- 删除也是一种变更：用带 `deleted: true` 的标记代替直接删除，这样以后同步时才能把删除传到其他设备。

### 键的约定

| 键 | 内容 | 说明 |
|---|---|---|
| `progress:{moduleId}` | `ModuleProgress.toJson()` | 现有键 `module_progress_{moduleId}`，首次启动时迁移过来 |
| `wrong:{questionType}:{input}` | `WrongQuestionRecord.toJson()` | 现有的单个大键 `wrong_questions` 拆成每题一个键 |

后续新增的数据也沿用这个格式，例如 `srs:{itemKey}` 存间隔重复状态，`daily:{yyyy-MM-dd}` 存每日汇总。

错题拆成每题一个键，是为了以后两台设备同时新增错题时不会互相覆盖。错题按题型和输入去重，总数有上限，大约几百条，单独成键不会造成数量膨胀。

### 改动

1. 新增 `lib/services/local_store.dart`，作为对 SharedPreferences 的薄封装：

   ```dart
   class LocalStore {
     Future<Map<String, dynamic>?> get(String key);
     Future<void> put(String key, Map<String, dynamic> value); // 自动写入 updatedAt 并记录变更
     Future<void> delete(String key);                           // 写入删除标记
     Future<List<String>> keysWithPrefix(String prefix);
     Future<Map<String, Map<String, dynamic>>> changedSince(int timestamp);
   }
   ```

   `put` 和 `delete` 内部还要维护一个"待同步键集合"，供以后的同步实现读取。

2. `ModuleProgress` 和 `WrongQuestionRecord` 都增加 `updatedAt` 字段，旧数据缺失时取 0。
3. `StorageService` 的公开方法签名保持不变，内部改为调用 `LocalStore`，这样界面层不用改。
4. 新增一次性迁移，在启动时执行一次，完成后写入 `schema_version = 2`：
   - 把所有 `module_progress_*` 迁到 `progress:*`。
   - 把 `wrong_questions` 列表拆成多个 `wrong:*` 键。
   - 迁移成功后再删除旧键。

### 验收

- 拿一台已有旧数据的设备覆盖安装新版本，进度页和错题本的内容与升级前一致。
- 为迁移逻辑补一个单元测试：输入旧格式的 SharedPreferences 数据，输出新格式。

---

## 第 4 步：定义同步接口，本阶段只用空实现

### 接口

新增 `lib/services/sync/sync_backend.dart`：

```dart
abstract class SyncBackend {
  /// 拉取 since 之后云端有变化的条目
  Future<Map<String, Map<String, dynamic>>> pull({required int since});

  /// 推送本地有变化的条目，返回已被云端接受的键
  Future<Set<String>> push(Map<String, Map<String, dynamic>> items);
}

class NoopSyncBackend implements SyncBackend { ... } // 本阶段使用
```

新增 `lib/services/sync/sync_engine.dart`，负责：

- 调度：应用启动、回到前台、答完一轮时各触发一次。失败时静默，下次再试，绝不阻塞界面。
- 合并：对每个键比较 `updatedAt`，较新者胜，删除标记同样参与比较。
- 合并后通知界面刷新。可以用一个 `ValueNotifier<int>` 作为数据版本号，让 `ProgressScreen` 和 `ReviewScreen` 监听后重新加载。

### 以后接入云端时

| 方向 | 实现 | 额外工作 |
|---|---|---|
| 只做 iOS | `CloudKitSyncBackend`：每个键一条记录，字段为 `value`（JSON 字符串）和 `updatedAt`；写入时先取回服务器记录再修改，或用 `CKModifyRecordsOperation` 配合 `.changedKeys` | 社交功能用 Game Center |
| 同时做 Android | `HttpSyncBackend`：对应服务端的一张 `SyncItem(userId, key, value, updatedAt)` 表，以及拉取、推送两个接口 | 匿名账号；令牌存钥匙串（`flutter_secure_storage`）；之后再绑定 Apple 登录或手机号、邮箱 |

两种实现都只需替换 `SyncBackend`，`LocalStore`、`SyncEngine` 和界面层不用改。

### 验收

- 合并逻辑有单元测试，覆盖本地较新、云端较新、一方删除另一方修改、新增键这几种情况。
- 使用 `NoopSyncBackend` 时，应用行为和第 3 步完成后完全一致。

---

## 第 5 步（可选）：导出与导入

在接入云端之前，作为换机时的兜底方案。

- 在进度页的设置区加两个入口："导出学习数据"和"导入学习数据"。
- 导出：把 `LocalStore` 里所有 `progress:*` 和 `wrong:*` 打包成一个 JSON 文件，带上 `schema_version` 和导出时间，通过系统分享面板发出。
- 导入：选择文件，校验 `schema_version`，再走 `SyncEngine` 同样的合并逻辑，所以不会覆盖本地较新的数据。

---

## 执行顺序与提交建议

每一步单独提交，任何一步都可以单独回滚：

1. `chore: 移除 CloudKit 与 Apple 登录`
2. `feat: 题目携带题型与输入，熟练度生效`
3. `refactor: 本地存储按键拆分并迁移旧数据`
4. `feat: 同步接口与合并引擎（空实现）`
5. `feat: 学习数据导出与导入`（可选）

第 2 步和第 3 步互不依赖，可以对调。第 4 步依赖第 3 步。

## 什么时候重新决定云端方案

出现以下任一情况时，回到"以后接入云端时"那张表做选择：

- 准备发布 Android 版。
- 开始做排行榜、好友等跨用户功能。
- 有用户反馈换机或重装后丢失进度，而导出导入不够用。
