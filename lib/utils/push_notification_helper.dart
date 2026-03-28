import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

/// プッシュ通知を送信するヘルパークラス
class PushNotificationHelper {
  final SupabaseClient _supabaseClient;

  PushNotificationHelper(this._supabaseClient);

  /// 指定したユーザーIDsにプッシュ通知を送信
  Future<void> sendPushNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (userIds.isEmpty) {
      debugPrint('sendPushNotifications: No user IDs provided');
      return;
    }

    try {
      debugPrint(
        'sendPushNotifications: Sending to ${userIds.length} users: $userIds',
      );

      // Supabase Edge Functionを呼び出してプッシュ通知を送信
      // Edge Function側でService Roleキーを使ってトークンを取得する
      debugPrint(
        'sendPushNotifications: Calling Edge Function with ${userIds.length} user IDs',
      );
      final response = await _supabaseClient.functions.invoke(
        'send-push-notification',
        body: {
          'user_ids': userIds, // トークンではなくユーザーIDを送信
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      if (response.status != 200) {
        debugPrint(
          'sendPushNotifications: Failed with status ${response.status}: ${response.data}',
        );
      } else {
        debugPrint(
          'sendPushNotifications: Success! Response: ${response.data}',
        );
      }
    } catch (e) {
      debugPrint('sendPushNotifications: Error - $e');
      // プッシュ通知の失敗は致命的エラーとしない（アプリ内通知は別途送信される）
    }
  }
}
