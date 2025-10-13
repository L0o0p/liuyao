import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/storage_service.dart';

class AppleSignInButton extends StatefulWidget {
  final VoidCallback? onSignInSuccess;
  final VoidCallback? onSignInFailed;

  const AppleSignInButton({
    super.key,
    this.onSignInSuccess,
    this.onSignInFailed,
  });

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await StorageService.enableCloudSync();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Apple 登录成功，已启用云端同步'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSignInSuccess?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Apple 登录失败'),
              backgroundColor: Colors.red,
            ),
          );
          widget.onSignInFailed?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 登录出错: $e'), backgroundColor: Colors.red),
        );
        widget.onSignInFailed?.call();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isLoading ? null : _handleSignIn,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  const Icon(
                    CupertinoIcons.person_crop_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '使用 Apple 登录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 云端同步状态指示器
class CloudSyncIndicator extends StatelessWidget {
  const CloudSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Future.value(StorageService.isCloudSyncEnabled),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled ? Colors.green : Colors.grey,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEnabled ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: isEnabled ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                isEnabled ? '云端同步已启用' : '云端同步未启用',
                style: TextStyle(
                  fontSize: 12,
                  color: isEnabled ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 同步按钮
class SyncButton extends StatefulWidget {
  const SyncButton({super.key});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    if (!StorageService.isCloudSyncEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先登录 Apple ID 启用云端同步'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await StorageService.syncFromCloud();
      await StorageService.syncToCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 数据同步完成'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 同步失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isSyncing ? null : _handleSync,
      icon: _isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      tooltip: '同步数据',
    );
  }
}
