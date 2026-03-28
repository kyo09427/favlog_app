import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/supabase_fcm_token_repository.dart';
import '../data/repositories/supabase_auth_repository.dart';

// トップレベル関数：バックグラウンド通知のハンドラ
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // バックグラウンドで通知を受信した時の処理
  debugPrint('Background message received: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Ref _ref;

  FCMService(this._ref)
    : _messaging = FirebaseMessaging.instance,
      _localNotifications = FlutterLocalNotificationsPlugin();

  /// FCMサービスの初期化
  Future<void> initialize() async {
    try {
      // 通知権限のリクエスト
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else {
        debugPrint('User declined or has not accepted permission');
        return;
      }

      // FCMトークンの取得
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // トークンの更新を監視
      _messaging.onTokenRefresh.listen(_saveToken);

      // フォアグラウンド通知のハンドラを設定
      setupForegroundHandler();

      // バックグラウンド通知のハンドラを設定
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // ローカル通知の初期化
      await _initializeLocalNotifications();

      // Firebase通知タップ時の処理
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      _messaging.getInitialMessage().then((message) {
        if (message != null) {
          _handleNotificationTap(message);
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize FCM: $e');
    }
  }

  /// ログイン後にFCMトークンを取得・保存（公開メソッド）
  Future<void> refreshToken() async {
    try {
      debugPrint('refreshToken: Getting FCM token...');
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('refreshToken: Token obtained, saving...');
        await _saveToken(token);
        debugPrint('refreshToken: FCM token refreshed and saved');
      } else {
        debugPrint('refreshToken: No token available');
      }
    } catch (e) {
      debugPrint('refreshToken: Failed to refresh FCM token: $e');
    }
  }

  /// トークンをサーバーに保存
  Future<void> _saveToken(String token) async {
    try {
      debugPrint('_saveToken: Starting to save token: ${token.substring(0, 20)}...');

      final authRepository = _ref.read(authRepositoryProvider);
      final currentUser = authRepository.getCurrentUser();

      if (currentUser == null) {
        debugPrint('_saveToken: No current user, skipping token save');
        return;
      }

      debugPrint('_saveToken: Current user ID: ${currentUser.id}');
      final fcmTokenRepository = _ref.read(fcmTokenRepositoryProvider);

      // デバイスタイプの取得
      String? deviceType;
      if (kIsWeb) {
        deviceType = 'web';
      } else if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      }

      if (deviceType == null) {
        debugPrint(
          '_saveToken: Unable to determine device type, skipping token save',
        );
        return;
      }

      debugPrint('_saveToken: Device type: $deviceType');
      debugPrint('_saveToken: Calling fcmTokenRepository.saveToken...');
      await fcmTokenRepository.saveToken(currentUser.id, token, deviceType);
      debugPrint('_saveToken: FCM token saved successfully!');
    } catch (e) {
      debugPrint('_saveToken: Failed to save FCM token: $e');
    }
  }

  /// ローカル通知の初期化
  Future<void> _initializeLocalNotifications() async {
    // Web版ではローカル通知を使用しない
    if (kIsWeb) {
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }
  }

  /// フォアグラウンド通知のハンドラを設定
  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Foreground message received: ${message.notification?.title}');

      // フォアグラウンドで通知を受信した場合、ローカル通知を表示
      if (message.notification != null) {
        await _showLocalNotification(message);
      }
    });
  }

  /// ローカル通知を表示
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Web版ではローカル通知を使用しない
    if (kIsWeb) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel', // チャネルID
        'High Importance Notifications', // チャネル名
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        details,
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  /// 通知タップ時の処理
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // TODO: レビュー詳細画面への遷移を実装
    // 例: context.push('/review/${message.data['review_id']}');
  }

  /// トークンの削除（ログアウト時などに使用）
  Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final fcmTokenRepository = _ref.read(fcmTokenRepositoryProvider);
        await fcmTokenRepository.deleteToken(token);
        await _messaging.deleteToken();
        debugPrint('FCM token deleted');
      }
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
  }
}

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService(ref);
});
