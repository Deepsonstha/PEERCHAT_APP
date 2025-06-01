import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../data/models/chat_message.dart';
import '../data/models/user.dart';

class NotificationService extends GetxService {
  static NotificationService get instance => Get.find<NotificationService>();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification settings
  final RxBool _notificationsEnabled = true.obs;
  final RxBool _soundEnabled = true.obs;
  final RxBool _vibrationEnabled = true.obs;
  final RxBool _privateMessageNotifications = true.obs;

  // Getters for settings
  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get soundEnabled => _soundEnabled.value;
  bool get vibrationEnabled => _vibrationEnabled.value;
  bool get privateMessageNotifications => _privateMessageNotifications.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNotifications();
  }

  /// Initialize notification system
  Future<void> _initializeNotifications() async {
    try {
      log('Initializing notification service...');

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: _onNotificationTapped);

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      // Request permissions for iOS
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }

      log('Notification service initialized successfully');
    } catch (e) {
      log('Error initializing notifications: $e');
    }
  }

  /// Request Android notification permissions
  Future<void> _requestAndroidPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        log('Android notification permission granted: $granted');
      }
    } catch (e) {
      log('Error requesting Android permissions: $e');
    }
  }

  /// Request iOS notification permissions
  Future<void> _requestIOSPermissions() async {
    try {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final bool? granted = await iosImplementation.requestPermissions(alert: true, badge: true, sound: true);
        log('iOS notification permission granted: $granted');
      }
    } catch (e) {
      log('Error requesting iOS permissions: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    try {
      final String? payload = notificationResponse.payload;
      log('Notification tapped with payload: $payload');

      if (payload != null) {
        // Parse payload and navigate to appropriate screen
        final parts = payload.split('|');
        if (parts.length >= 2) {
          final String type = parts[0];
          final String userId = parts[1];

          if (type == 'private_message') {
            // Navigate to private chat screen
            // This would need to be implemented based on your navigation structure
            log('Navigate to private chat with user: $userId');
          }
        }
      }
    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }

  /// Show notification for private message
  Future<void> showPrivateMessageNotification(ChatMessage message, User sender) async {
    if (!_notificationsEnabled.value || !_privateMessageNotifications.value) {
      return;
    }

    try {
      // Create notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'private_messages',
        'Private Messages',
        channelDescription: 'Notifications for private messages',
        importance: Importance.high,
        priority: Priority.high,
        playSound: _soundEnabled.value,
        enableVibration: _vibrationEnabled.value,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(message.content, contentTitle: '${sender.name} sent you a message', summaryText: 'PeerChat'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        message.id.hashCode, // Use message ID hash as notification ID
        '${sender.name} sent you a message',
        message.content,
        notificationDetails,
        payload: 'private_message|${sender.id}',
      );

      log('Private message notification shown for message from ${sender.name}');
    } catch (e) {
      log('Error showing private message notification: $e');
    }
  }

  /// Show notification for group message
  Future<void> showGroupMessageNotification(ChatMessage message, User sender) async {
    if (!_notificationsEnabled.value) {
      return;
    }

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'group_messages',
        'Group Messages',
        channelDescription: 'Notifications for group messages',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: _soundEnabled.value,
        enableVibration: _vibrationEnabled.value,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(message.content, contentTitle: '${sender.name} in PeerChat', summaryText: 'Group Chat'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _flutterLocalNotificationsPlugin.show(
        message.id.hashCode,
        'New message in PeerChat',
        '${sender.name}: ${message.content}',
        notificationDetails,
        payload: 'group_message|${sender.id}',
      );

      log('Group message notification shown for message from ${sender.name}');
    } catch (e) {
      log('Error showing group message notification: $e');
    }
  }

  /// Show user joined notification
  Future<void> showUserJoinedNotification(User user) async {
    if (!_notificationsEnabled.value) {
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'user_events',
        'User Events',
        channelDescription: 'Notifications for user join/leave events',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: false, presentSound: false);

      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _flutterLocalNotificationsPlugin.show(
        user.id.hashCode,
        'User Joined',
        '${user.name} joined the chat',
        notificationDetails,
        payload: 'user_joined|${user.id}',
      );

      log('User joined notification shown for ${user.name}');
    } catch (e) {
      log('Error showing user joined notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      log('All notifications cancelled');
    } catch (e) {
      log('Error cancelling notifications: $e');
    }
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      log('Notification cancelled: $id');
    } catch (e) {
      log('Error cancelling notification: $e');
    }
  }

  /// Update notification settings
  void updateNotificationSettings({bool? notificationsEnabled, bool? soundEnabled, bool? vibrationEnabled, bool? privateMessageNotifications}) {
    if (notificationsEnabled != null) {
      _notificationsEnabled.value = notificationsEnabled;
    }
    if (soundEnabled != null) {
      _soundEnabled.value = soundEnabled;
    }
    if (vibrationEnabled != null) {
      _vibrationEnabled.value = vibrationEnabled;
    }
    if (privateMessageNotifications != null) {
      _privateMessageNotifications.value = privateMessageNotifications;
    }

    log('Notification settings updated');
  }

  /// Get notification settings
  Map<String, bool> getNotificationSettings() {
    return {
      'notificationsEnabled': _notificationsEnabled.value,
      'soundEnabled': _soundEnabled.value,
      'vibrationEnabled': _vibrationEnabled.value,
      'privateMessageNotifications': _privateMessageNotifications.value,
    };
  }

  /// Check if notifications are available
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          return await androidImplementation.areNotificationsEnabled() ?? false;
        }
      }
      return true; // Assume enabled for other platforms
    } catch (e) {
      log('Error checking notification status: $e');
      return false;
    }
  }
}
