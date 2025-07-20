    import 'package:flutter_local_notifications/flutter_local_notifications.dart';
    import 'package:timezone/timezone.dart' as tz;
    import 'package:timezone/data/latest.dart' as tz;

    class NotificationService {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      Future<void> initialize() async {
        // Initialize timezone data
        tz.initializeTimeZones();
        final location = tz.getLocation('Asia/Kolkata'); // Set your desired timezone
        tz.setLocalLocation(location);

        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher'); // Your app icon

        const DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const InitializationSettings initializationSettings =
            InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) async {
            // Handle notification tap
            if (response.payload != null) {
              print('notification payload: ${response.payload}');
            }
          },
        );
      }

      Future<void> scheduleHydrationNotification(
          DateTime scheduledTime, String message) async {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'hydration_channel_id', // Channel ID
          'Hydration Reminders', // Channel Name
          channelDescription: 'Reminders to drink water throughout the day',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );

        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails();

        const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

        await flutterLocalNotificationsPlugin.zonedSchedule(
          0, // Notification ID
          'Hydration Reminder',
          message,
          tz.TZDateTime.from(scheduledTime, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime, // Corrected from absoluteLocal
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
          payload: 'hydration_payload',
        );
      }

      // Method to cancel all pending notifications (useful on logout/account deletion)
      Future<void> cancelAllNotifications() async {
        await flutterLocalNotificationsPlugin.cancelAll();
      }
    }
