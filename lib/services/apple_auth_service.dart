import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AppleAuthService {
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
}
