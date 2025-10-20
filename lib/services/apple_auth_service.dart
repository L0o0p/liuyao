import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppleAuthService {
  static const String _userIdKey = 'apple_user_id';
  static const String _isSignedInKey = 'is_apple_signed_in';

  static Future<AuthorizationCredentialAppleID?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (kDebugMode) {
        print('用户唯一ID: ${credential.userIdentifier}');
        print('邮箱: ${credential.email}');
        print('姓名: ${credential.givenName} ${credential.familyName}');
      }

      // 保存登录状态和用户ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, credential.userIdentifier ?? '');
      await prefs.setBool(_isSignedInKey, true);

      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('Apple 登录失败: $e');
      }
      return null;
    }
  }

  static Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  /// 检查用户是否已经登录Apple ID
  static Future<bool> isUserSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSignedIn = prefs.getBool(_isSignedInKey) ?? false;

      if (!isSignedIn) {
        return false;
      }

      // 如果本地显示已登录，验证Apple服务器上的状态
      final userId = prefs.getString(_userIdKey);
      if (userId == null || userId.isEmpty) {
        return false;
      }

      final credentialState = await SignInWithApple.getCredentialState(userId);
      final isValid = credentialState == CredentialState.authorized;

      // 如果服务器状态无效，清除本地登录状态
      if (!isValid) {
        await signOut();
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('检查Apple登录状态失败: $e');
      }
      return false;
    }
  }

  /// 退出登录
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.setBool(_isSignedInKey, false);
  }
}
