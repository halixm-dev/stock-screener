import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stock_screener/data/models/screener_result.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showGroupedNotification(List<ScreenResult> freshSignals) async {
    if (kIsWeb) return;
    if (freshSignals.isEmpty) return;

    final String title = '${freshSignals.length} New Fresh Signals Detected';

    // Create a summarized body
    // e.g. "AAPL (Buy), MSFT (Sell), BBCA (Buy)"
    final String body = freshSignals
        .map((r) {
          final signalStr = r.signal == SignalTypeHive.buy ? 'Buy' : 'Sell';
          return '${r.symbol} ($signalStr)';
        })
        .join(', ');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'screener_fresh_signals',
          'Fresh Signals',
          channelDescription: 'Notifications for fresh indicator signals',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.active,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0, // Using 0 so we always replace the previous notification
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
