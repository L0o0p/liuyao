# CloudKit 配置指南

## 🚨 当前问题

您遇到的错误 `Type is not marked indexable: Progress` 是因为 CloudKit 需要在 Apple Developer Console 中预先定义记录类型。

## 🔧 解决方案

### 方案 1: 使用 CloudKit Dashboard 配置（推荐）

1. **登录 Apple Developer Console**
   - 访问 [developer.apple.com](https://developer.apple.com)
   - 使用您的 Apple ID 登录

2. **进入 CloudKit Dashboard**
   - 选择您的 App ID
   - 点击 "CloudKit Dashboard"
   - 选择您的 CloudKit Container

3. **创建记录类型**
   在 "Schema" 标签页中，创建以下记录类型：

   **UserProgress 记录类型:**
   ```
   Record Type: UserProgress
   Fields:
   - word (String, Indexed)
   - score (Int64, Indexed)
   - timestamp (Date/Time, Indexed)
   ```

   **UserModuleProgress 记录类型:**
   ```
   Record Type: UserModuleProgress
   Fields:
   - moduleId (String, Indexed)
   - progress (Double, Indexed)
   - completedQuestions (Int64, Indexed)
   - totalQuestions (Int64, Indexed)
   - timestamp (Date/Time, Indexed)
   ```

   **UserWrongQuestion 记录类型:**
   ```
   Record Type: UserWrongQuestion
   Fields:
   - questionText (String, Indexed)
   - correctAnswer (String, Indexed)
   - userAnswer (String, Indexed)
   - moduleId (String, Indexed)
   - reviewCount (Int64, Indexed)
   - timestamp (Date/Time, Indexed)
   ```

4. **部署 Schema**
   - 点击 "Deploy Schema Changes"
   - 选择 "Development" 环境
   - 确认部署

### 方案 2: 使用代码自动创建（临时方案）

我已经修改了 CloudKit 插件，使其能够优雅地处理记录类型不存在的情况。现在当记录类型不存在时，会返回空数组而不是错误。

### 方案 3: 简化记录类型（当前实现）

我已经将记录类型名称改为：
- `Progress` → `UserProgress`
- `ModuleProgress` → `UserModuleProgress`  
- `WrongQuestion` → `UserWrongQuestion`

这样可以避免与系统保留名称冲突。

## 📱 测试步骤

1. **热重载应用**
   ```bash
   flutter run
   ```

2. **测试 Apple 登录**
   - 在进度页面点击 "使用 Apple 登录"
   - 应该不再出现 CloudKit 错误

3. **测试数据同步**
   - 登录成功后，尝试学习一些内容
   - 检查数据是否正确保存到本地和云端

## 🔍 故障排除

### 如果仍然出现错误：

1. **检查 CloudKit 容器配置**
   - 确保在 Xcode 中正确配置了 CloudKit 能力
   - 确保 Bundle ID 与 Apple Developer Console 中的一致

2. **检查网络连接**
   - 确保设备连接到互联网
   - 确保 iCloud 账户已登录

3. **检查开发者账户**
   - 确保 Apple Developer 账户已付费
   - 确保 CloudKit 服务已启用

### 常见错误及解决方案：

| 错误信息 | 解决方案 |
|---------|---------|
| `Type is not marked indexable` | 在 CloudKit Dashboard 中创建记录类型 |
| `Container not found` | 检查 Xcode 中的 CloudKit 配置 |
| `Authentication failed` | 检查 Apple ID 登录状态 |
| `Network error` | 检查网络连接和 iCloud 状态 |

## 📋 验证清单

- [ ] Apple Developer Console 中已创建 CloudKit 容器
- [ ] CloudKit Dashboard 中已创建记录类型
- [ ] Xcode 中已启用 CloudKit 能力
- [ ] 设备已登录 iCloud
- [ ] 应用已重新编译和安装

## 🚀 下一步

1. 按照上述步骤配置 CloudKit Dashboard
2. 重新运行应用
3. 测试 Apple 登录和云端同步功能
4. 如果仍有问题，请检查控制台日志获取更详细的错误信息

---

*注意：CloudKit 记录类型一旦部署到生产环境就不能删除，请谨慎操作。*

