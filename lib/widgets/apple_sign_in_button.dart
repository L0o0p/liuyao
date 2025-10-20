import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/storage_service.dart';

class AppleSignInButton extends StatefulWidget {
  final VoidCallback? onSignInSuccess;
  final VoidCallback? onSignInFailed;
  final VoidCallback? onSignOut;

  const AppleSignInButton({
    super.key,
    this.onSignInSuccess,
    this.onSignInFailed,
    this.onSignOut,
  });

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  bool _isLoading = false;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    final isSignedIn = StorageService.isCloudSyncEnabled;
    if (mounted) {
      setState(() {
        _isSignedIn = isSignedIn;
      });
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await StorageService.signOut();
      if (mounted) {
        setState(() {
          _isSignedIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 已退出登录，云端同步已禁用'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onSignOut?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 退出登录失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await StorageService.enableCloudSync();

      if (success) {
        if (mounted) {
          setState(() {
            _isSignedIn = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                StorageService.isCloudSyncEnabled
                    ? '✅ Apple 登录成功，已启用云端同步'
                    : '✅ Apple 登录成功，使用本地存储',
              ),
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
          onTap: _isLoading
              ? null
              : (_isSignedIn ? _handleSignOut : _handleSignIn),
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
                  Icon(
                    _isSignedIn
                        ? CupertinoIcons.person_crop_circle_fill
                        : CupertinoIcons.person_crop_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isSignedIn ? '退出 Apple 登录' : '使用 Apple 登录',
                    style: const TextStyle(
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
class CloudSyncIndicator extends StatefulWidget {
  const CloudSyncIndicator({super.key});

  @override
  State<CloudSyncIndicator> createState() => _CloudSyncIndicatorState();
}

class _CloudSyncIndicatorState extends State<CloudSyncIndicator> {
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    final isEnabled = StorageService.isCloudSyncEnabled;
    if (mounted && _isEnabled != isEnabled) {
      setState(() {
        _isEnabled = isEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 每次build时都检查状态
    _updateStatus();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isEnabled
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEnabled ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isEnabled ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: _isEnabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            _isEnabled ? '云端同步已启用' : '云端同步未启用',
            style: TextStyle(
              fontSize: 12,
              color: _isEnabled ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
