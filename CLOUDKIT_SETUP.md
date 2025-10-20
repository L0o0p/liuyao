# CloudKit 配置指南

本文档详细说明如何在 CloudKit Dashboard 中配置记录类型和索引，以支持应用的数据同步功能。

## 问题诊断

如果您在日志中看到以下错误：
- ❌ `Field 'recordName' is not marked queryable`
- ❌ `Type is not marked indexable: Progress`
- ❌ `Type is not marked indexable: ModuleProgress`

说明 CloudKit 的记录类型和索引尚未配置。

## 配置步骤

### 1. 访问 CloudKit Dashboard

1. 打开 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. 登录您的 Apple Developer 账号
3. 选择您的容器：`iCloud.com.loop.liuyao`
4. 选择环境：**Development**（开发环境）

### 2. 配置记录类型和索引

应用使用以下4个记录类型，每个都需要配置索引才能进行查询：

#### 2.1 Progress（学习进度）

1. 在左侧菜单选择 **Schema** → **Record Types**
2. 如果 `Progress` 类型不存在，点击 **+** 创建
3. 点击 `Progress` 进入编辑界面
4. 添加以下字段：

| 字段名 | 类型 | 说明 |
|-------|------|------|
| `word` | String | 学习的词条 |
| `score` | Int(64) | 分数 |
| `timestamp` | Date/Time | 时间戳 |

5. 配置索引：
   - 点击 **Indexes** 标签
   - 点击 **Add Basic Index**
   - 选择 `timestamp` 字段
   - Index Type: `QUERYABLE`
   - Order: `DESCENDING`（降序，最新的在前）
   - 点击 **Save**

#### 2.2 ModuleProgress（模块进度）

1. 创建或编辑 `ModuleProgress` 记录类型
2. 添加以下字段：

| 字段名 | 类型 | 说明 |
|-------|------|------|
| `moduleId` | String | 模块ID |
| `progress` | Double | 进度百分比 |
| `completedQuestions` | Int(64) | 已完成题目数 |
| `totalQuestions` | Int(64) | 总题目数 |
| `timestamp` | Date/Time | 时间戳 |

3. 配置索引：
   - **Indexes** → **Add Basic Index**
   - 字段：`moduleId`
   - Index Type: `QUERYABLE`
   - 点击 **Save**

#### 2.3 WrongQuestion（错题记录）

1. 创建或编辑 `WrongQuestion` 记录类型
2. 添加以下字段：

| 字段名 | 类型 | 说明 |
|-------|------|------|
| `questionText` | String | 问题文本 |
| `correctAnswer` | String | 正确答案 |
| `userAnswer` | String | 用户答案 |
| `moduleId` | String | 模块ID |
| `reviewCount` | Int(64) | 复习次数 |
| `timestamp` | Date/Time | 时间戳 |

3. 配置索引：
   - **Indexes** → **Add Basic Index**
   - 字段：`moduleId`
   - Index Type: `QUERYABLE`
   - 点击 **Save**

#### 2.4 TestRecord（测试记录）

这是用于测试连接的记录类型：

1. 创建或编辑 `TestRecord` 记录类型
2. 添加以下字段：

| 字段名 | 类型 | 说明 |
|-------|------|------|
| `message` | String | 测试消息 |
| `timestamp` | Date/Time | 时间戳 |

3. 配置索引：
   - **Indexes** → **Add Basic Index**
   - 字段：`timestamp`
   - Index Type: `QUERYABLE`
   - 点击 **Save**

### 3. 保存更改

1. 配置完所有记录类型和索引后，点击页面顶部的 **Save Changes**
2. 等待 CloudKit 部署更改（通常需要几分钟）

### 4. 测试配置

1. 重新运行您的应用
2. 检查日志，应该看到：
   ```
   ✅ CloudKit数据拉取成功！
   📊 从CloudKit拉取到 X 条模块进度记录
   📋 CloudKit状态: 完全正常 ✅
   ```

## 部署到生产环境

完成开发环境测试后，需要将Schema部署到生产环境：

1. 在 CloudKit Dashboard 中，切换到 **Development** 环境
2. 点击顶部的 **Deploy Schema Changes...**
3. 选择 **Production** 环境
4. 确认部署

⚠️ **注意**：生产环境的Schema无法删除或修改字段类型，请确保在开发环境充分测试后再部署。

## 常见问题

### Q1: 为什么需要配置索引？

CloudKit 要求任何可查询的字段都必须配置索引。即使是简单的 `NSPredicate(value: true)` 查询，也需要至少一个索引才能执行。

### Q2: 可以通过代码自动创建索引吗？

不可以。CloudKit 不支持通过代码自动创建记录类型和索引，必须在 Dashboard 中手动配置。

### Q3: Development 和 Production 环境的区别？

- **Development**：用于开发和测试，可以随意修改Schema
- **Production**：用于正式发布的应用，Schema修改受限

### Q4: 如果不配置CloudKit会怎样？

应用会正常运行，但云端同步功能将不可用。所有数据会保存在本地（SharedPreferences）。

## 验证清单

配置完成后，请确认：

- [ ] 所有4个记录类型都已创建（Progress、ModuleProgress、WrongQuestion、TestRecord）
- [ ] 每个记录类型都有所需的字段
- [ ] 每个记录类型至少有一个可查询索引
- [ ] 点击了 **Save Changes** 并等待部署完成
- [ ] 重新运行应用，查看日志确认没有错误

## 技术支持

如果遇到问题，请检查：
1. Apple Developer 账号是否有效
2. 容器ID是否正确：`iCloud.com.loop.liuyao`
3. iOS设备是否登录了iCloud账号
4. 网络连接是否正常

---

配置完成后，您的应用将支持跨设备的学习进度和错题同步！

