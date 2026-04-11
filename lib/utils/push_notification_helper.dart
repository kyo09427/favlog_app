import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/supabase_provider.dart';
import 'package:favlog_app/core/utils/app_logger.dart';

final pushNotificationHelperProvider = Provider<PushNotificationHelper>((ref) {
  return PushNotificationHelper(ref.watch(supabaseProvider));
});

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
      AppLogger.log('sendPushNotifications: No user IDs provided');
      return;
    }

    try {
      AppLogger.log(
        'sendPushNotifications: Sending to ${userIds.length} users: $userIds',
      );

      // Supabase Edge Functionを呼び出してプッシュ通知を送信
      // Edge Function側でService Roleキーを使ってトークンを取得する
      AppLogger.log(
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
        AppLogger.log(
          'sendPushNotifications: Failed with status ${response.status}: ${response.data}',
        );
      } else {
        AppLogger.log(
          'sendPushNotifications: Success! Response: ${response.data}',
        );
      }
    } catch (e) {
      AppLogger.log('sendPushNotifications: Error - $e');
      // プッシュ通知の失敗は致命的エラーとしない（アプリ内通知は別途送信される）
    }
  }
}
