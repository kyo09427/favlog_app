import '../../domain/models/fcm_token.dart';

abstract class FCMTokenRepository {
  /// ユーザーのFCMトークンを保存
  Future<void> saveToken(String userId, String token, String? deviceType);

  /// 指定したユーザーIDsのFCMトークン一覧を取得
  Future<List<String>> getTokensByUserIds(List<String> userIds);

  /// 指定したトークンを削除
  Future<void> deleteToken(String token);

  /// 指定したユーザーの全トークンを取得
  Future<List<FCMToken>> getTokensByUserId(String userId);
}
