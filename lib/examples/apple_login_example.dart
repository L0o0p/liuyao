import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/apple_sign_in_button.dart';

/// Apple 登录和 CloudKit 同步使用示例
///
/// 这个示例展示了如何在应用中集成 Apple 登录和 CloudKit 同步功能
class AppleLoginExample extends StatefulWidget {
  const AppleLoginExample({super.key});

  @override
  State<AppleLoginExample> createState() => _AppleLoginExampleState();
}

class _AppleLoginExampleState extends State<AppleLoginExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apple 登录示例')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('功能说明', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      '• 点击"使用 Apple 登录"按钮进行登录\n'
                      '• 登录成功后自动启用 CloudKit 云端同步\n'
                      '• 学习进度和错题记录会自动同步到云端\n'
                      '• 支持多设备间数据同步',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 登录按钮
            if (!StorageService.isCloudSyncEnabled) ...[
              const Text(
                '登录 Apple ID 启用云端同步:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              AppleSignInButton(
                onSignInSuccess: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 登录成功！云端同步已启用'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                },
                onSignInFailed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ 登录失败，请重试'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ] else ...[
              // 已登录状态
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            '云端同步已启用',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('您的学习数据会自动同步到 iCloud'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await StorageService.syncToCloud();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ 同步到云端完成'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ 同步失败: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('同步到云端'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await StorageService.syncFromCloud();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ 从云端同步完成'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ 同步失败: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.cloud_download),
                            label: const Text('从云端同步'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 代码示例
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('代码示例', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '''// 1. 启用云端同步
final success = await StorageService.enableCloudSync();

// 2. 保存数据（自动同步到云端）
await StorageService.saveProgress(progress);
await StorageService.recordWrongQuestion(record);

// 3. 手动同步
await StorageService.syncToCloud();   // 同步到云端
await StorageService.syncFromCloud(); // 从云端同步

// 4. 检查同步状态
bool isEnabled = StorageService.isCloudSyncEnabled;
DateTime? lastSync = await StorageService.getLastSyncTime();''',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
