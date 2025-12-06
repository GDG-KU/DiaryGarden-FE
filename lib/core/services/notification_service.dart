import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      
      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS settings
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      final settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );
      
      await _notifications.initialize(settings);
      _initialized = true;
      
      debugPrint('🔔 NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService initialization failed: $e');
      // On web or unsupported platforms, silently fail
    }
  }

  /// Schedule daily reminder at specified time
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();
    
    // Cancel existing reminder first
    await cancelReminder();
    
    // Calculate next occurrence of the specified time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'diary_reminder',
      '일기 리마인더',
      channelDescription: '매일 일기 작성 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
    
    try {
      await _notifications.zonedSchedule(
        0, // Notification ID
        '오늘 하루는 어땠나요? 🌳',
        '일기를 써서 나만의 숲에 나무를 심어보세요',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
      
      debugPrint('🔔 Daily reminder scheduled for $hour:$minute');
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  /// Cancel the daily reminder
  static Future<void> cancelReminder() async {
    try {
      await _notifications.cancel(0);
      debugPrint('🔕 Daily reminder cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel reminder: $e');
    }
  }
  
  /// Request notification permission (for iOS)
  static Future<bool> requestPermission() async {
    await initialize();
    
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
    
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
    return true;
  }
}
