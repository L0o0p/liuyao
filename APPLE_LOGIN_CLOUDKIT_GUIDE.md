# Apple 登录与 CloudKit 集成指南

本指南介绍如何在六爻学习 App 中使用 Apple 登录和 CloudKit 云端同步功能。

## 🍎 功能概述

- **Apple 登录**: 使用 Apple ID 进行安全登录
- **CloudKit 同步**: 自动将学习进度和错题记录同步到 iCloud
- **多设备同步**: 在 iPhone、iPad、Mac 等设备间保持数据一致
- **离线优先**: 本地存储为主，云端同步为辅

## 📱 用户使用流程

### 1. 启用云端同步

1. 打开应用，进入"进度"页面
2. 在云端同步区域点击"使用 Apple 登录"按钮
3. 系统会弹出 Apple 登录窗口
4. 使用 Face ID/Touch ID 或密码完成登录
5. 登录成功后，云端同步自动启用

### 2. 数据自动同步

- **学习进度**: 每次完成学习后自动同步
- **错题记录**: 答错题目时自动记录并同步
- **实时同步**: 数据变化时立即同步到云端

### 3. 手动同步

在进度页面的云端同步区域：
- 点击同步按钮进行手动同步
- 查看最后同步时间
- 同步状态实时显示

## 🛠 开发者集成

### 1. 依赖配置

确保 `pubspec.yaml` 包含：

```yaml
dependencies:
  sign_in_with_apple: ^6.0.0
  shared_preferences: ^2.2.2
```

### 2. iOS 配置

#### 2.1 启用 CloudKit 能力

1. 在 Xcode 中打开 `ios/Runner.xcworkspace`
2. 选择 Runner target
3. 在 "Signing & Capabilities" 中添加：
   - Sign in with Apple
   - CloudKit
4. 配置 CloudKit Container

#### 2.2 添加 Entitlements

确保 `ios/Runner/Runner.entitlements` 包含：

```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.$(CFBundleIdentifier)</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### 3. 代码使用

#### 3.1 初始化存储服务

在 `main.dart` 中：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化存储服务
  await StorageService.initialize();
  
  runApp(const MyApp());
}
```

#### 3.2 启用云端同步

```dart
// 启用 Apple 登录和 CloudKit 同步
final success = await StorageService.enableCloudSync();
if (success) {
  print('云端同步已启用');
}
```

#### 3.3 保存数据（自动同步）

```dart
// 保存学习进度（自动同步到云端）
await StorageService.saveProgress(progress);

// 记录错题（自动同步到云端）
await StorageService.recordWrongQuestion(record);
```

#### 3.4 手动同步

```dart
// 同步本地数据到云端
await StorageService.syncToCloud();

// 从云端同步数据到本地
await StorageService.syncFromCloud();
```

#### 3.5 检查同步状态

```dart
// 检查是否启用了云端同步
bool isEnabled = StorageService.isCloudSyncEnabled;

// 获取最后同步时间
DateTime? lastSync = await StorageService.getLastSyncTime();
```

### 4. UI 组件

#### 4.1 Apple 登录按钮

```dart
AppleSignInButton(
  onSignInSuccess: () {
    // 登录成功回调
    print('Apple 登录成功');
  },
  onSignInFailed: () {
    // 登录失败回调
    print('Apple 登录失败');
  },
)
```

#### 4.2 云端同步状态指示器

```dart
const CloudSyncIndicator()
```

#### 4.3 同步按钮

```dart
const SyncButton()
```

## 🔧 技术架构

### 1. 存储策略

- **本地存储**: SharedPreferences（主要）
- **云端存储**: CloudKit（备份和同步）
- **混合模式**: 本地优先，云端同步

### 2. 数据模型

#### CloudKit 记录类型

- **Progress**: 学习进度记录
  - `word`: 知识点
  - `score`: 分数
  - `timestamp`: 时间戳

- **ModuleProgress**: 模块进度记录
  - `moduleId`: 模块ID
  - `progress`: 进度百分比
  - `completedQuestions`: 完成题数
  - `totalQuestions`: 总题数
  - `timestamp`: 时间戳

- **WrongQuestion**: 错题记录
  - `questionText`: 题目文本
  - `correctAnswer`: 正确答案
  - `userAnswer`: 用户答案
  - `moduleId`: 模块ID
  - `reviewCount`: 复习次数
  - `timestamp`: 时间戳

### 3. 同步机制

1. **实时同步**: 数据变化时立即同步
2. **冲突解决**: 以最新时间戳为准
3. **错误处理**: 本地保存成功，云端失败不影响用户体验
4. **重试机制**: 网络恢复后自动重试

## 🚀 部署注意事项

### 1. Apple Developer 配置

1. 在 Apple Developer Console 中：
   - 启用 Sign in with Apple 服务
   - 配置 CloudKit 容器
   - 设置正确的 Bundle ID

### 2. 测试

- 在真机上测试（模拟器不支持 CloudKit）
- 测试多设备同步
- 测试网络异常情况

### 3. 隐私

- 遵循 Apple 隐私政策
- 在 App Store 描述中说明数据使用情况
- 提供数据删除选项

## 📋 常见问题

### Q: CloudKit 同步失败怎么办？
A: 检查网络连接、iCloud 登录状态、开发者配置是否正确。

### Q: 如何删除云端数据？
A: 目前需要用户在 iCloud 设置中手动删除应用数据。

### Q: 支持哪些设备？
A: 支持 iOS 13+ 的所有设备，包括 iPhone、iPad。

### Q: 数据安全性如何？
A: 使用 Apple 的端到端加密，数据存储在用户的 iCloud 中。

## 🔗 相关文档

- [Sign in with Apple 官方文档](https://developer.apple.com/sign-in-with-apple/)
- [CloudKit 官方文档](https://developer.apple.com/icloud/cloudkit/)
- [Flutter sign_in_with_apple 插件](https://pub.dev/packages/sign_in_with_apple)

---

*最后更新: 2025年10月13日*
