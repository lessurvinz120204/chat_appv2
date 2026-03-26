import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request Permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Local Notifications (to show banners while app is open)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // 3. Listen for Background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Listen for Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_id', 
              'Chat Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  static Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }
}

// Background handler must be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
}