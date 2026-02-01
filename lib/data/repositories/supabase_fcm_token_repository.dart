import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/fcm_token.dart';
import '../../domain/repositories/fcm_token_repository.dart';
import '../../main.dart';

final fcmTokenRepositoryProvider = Provider<FCMTokenRepository>((ref) {
  return SupabaseFCMTokenRepository(ref.watch(supabaseProvider));
});

class SupabaseFCMTokenRepository implements FCMTokenRepository {
  final SupabaseClient _supabaseClient;

  SupabaseFCMTokenRepository(this._supabaseClient);

  @override
  Future<void> saveToken(String userId, String token, String? deviceType) async {
    try {
      print('saveToken: Attempting to save token for user $userId');
      print('saveToken: Token: ${token.substring(0, 20)}..., Device: $deviceType');
      
      // device_typeは必須
      if (deviceType == null || deviceType.isEmpty) {
        throw Exception('Device type is required');
      }
      
      // upsert: 同じuser_id + device_typeの組み合わせがあれば更新、なければ挿入
      // これにより、1ユーザー・1デバイスタイプにつき1トークンのみ保持される
      await _supabaseClient.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': deviceType,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,device_type');
      
      print('saveToken: Successfully saved token to database');
    } catch (e) {
      print('saveToken: Error - $e');
      throw Exception('Failed to save FCM token: $e');
    }
  }

  @override
  Future<List<String>> getTokensByUserIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      print('getTokensByUserIds: Empty user IDs list');
      return [];
    }

    try {
      print('getTokensByUserIds: Fetching tokens for ${userIds.length} users: $userIds');
      final response = await _supabaseClient
          .from('fcm_tokens')
          .select('token')
          .inFilter('user_id', userIds);

      print('getTokensByUserIds: Raw response: $response');
      final tokens = (response as List)
          .map((json) => json['token'] as String)
          .toList();
      print('getTokensByUserIds: Extracted ${tokens.length} tokens');
      return tokens;
    } catch (e) {
      print('getTokensByUserIds: Error - $e');
      throw Exception('Failed to get FCM tokens by user IDs: $e');
    }
  }

  @override
  Future<void> deleteToken(String token) async {
    try {
      await _supabaseClient
          .from('fcm_tokens')
          .delete()
          .eq('token', token);
    } catch (e) {
      throw Exception('Failed to delete FCM token: $e');
    }
  }

  @override
  Future<List<FCMToken>> getTokensByUserId(String userId) async {
    try {
      final response = await _supabaseClient
          .from('fcm_tokens')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map((json) => FCMToken.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get FCM tokens by user ID: $e');
    }
  }
}
