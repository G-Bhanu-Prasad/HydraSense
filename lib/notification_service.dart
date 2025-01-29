import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_application_2/widgets/datetime_selector.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _notificationService.initialize();
  }

  Future<void> _scheduleNotification() async {
    final DateTime now = DateTime.now();
    final DateTime scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a future time"),
            backgroundColor: Color.fromARGB(255, 11, 3, 97),
          ),
        );
      }
      return;
    }

    await _notificationService.scheduleNotifications(scheduledDateTime);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Notification scheduled for ${scheduledDateTime.toString()}",
          ),
          backgroundColor: const Color.fromARGB(255, 11, 3, 97),
        ),
      );
    }
  }

  void _updateDateTime(DateTime date, TimeOfDay time) {
    setState(() {
      selectedDate = date;
      selectedTime = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _notificationService.showInstantNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Send Instant Notification"),
            ),
            const SizedBox(height: 24),
            const Text(
              "Schedule Notification",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DateTimeSelector(
              selectedDate: selectedDate,
              selectedTime: selectedTime,
              onDateTimeChaged: _updateDateTime,
            ),
            ElevatedButton(
              onPressed: _scheduleNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Schedule Notification"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final List<Map<String, dynamic>> hydrationSchedule = [
                  {
                    "time": const TimeOfDay(hour: 5, minute: 0),
                    "message": "Start your day with a glass of water! \n "
                  },
                  {
                    "time": const TimeOfDay(hour: 8, minute: 0),
                    "message": "Time for your morning hydration boost!"
                  },
                  {
                    "time": const TimeOfDay(hour: 10, minute: 0),
                    "message": "Stay refreshed! Drink some water now."
                  },
                  {
                    "time": const TimeOfDay(hour: 14, minute: 0),
                    "message": "Midday hydration check: Grab a glass!"
                  },
                  {
                    "time": const TimeOfDay(hour: 18, minute: 0),
                    "message": "Evening reminder: Keep hydrating!"
                  },
                  {
                    "time": const TimeOfDay(hour: 21, minute: 0),
                    "message": "End your day right: Drink some water."
                  },
                ];

                for (var schedule in hydrationSchedule) {
                  final TimeOfDay time = schedule["time"];
                  final String message = schedule["message"];
                  final now = DateTime.now();
                  final DateTime scheduledDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );

                  if (scheduledDateTime.isAfter(now)) {
                    await _notificationService.scheduleHydrationNotification(
                      scheduledDateTime,
                      message,
                    );
                  }
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Hydration notifications with messages scheduled."),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Schedule Hydration Notifications"),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    //print("Notification Checked: ${response.payload}");
  }

  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifies =
        AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Channel for instant notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifies =
        NotificationDetails(android: androidPlatformChannelSpecifies);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Hydration Reminder',
      'Time for water',
      platformChannelSpecifies,
      payload: 'instant',
    );
  }

  Future<void> scheduleNotifications(DateTime scheduledDateTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifies =
        AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifies =
        NotificationDetails(android: androidPlatformChannelSpecifies);

    final tz.TZDateTime tzScheduledDateTime =
        tz.TZDateTime.from(scheduledDateTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Hydration Reminder',
      'Time for water',
      tzScheduledDateTime,
      platformChannelSpecifies,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleHydrationNotification(
      DateTime scheduledDateTime, String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifies =
        AndroidNotificationDetails(
      'hydration_channel',
      'Hydration Notifications',
      channelDescription: 'Channel for hydration reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifies =
        NotificationDetails(android: androidPlatformChannelSpecifies);

    final tz.TZDateTime tzScheduledDateTime =
        tz.TZDateTime.from(scheduledDateTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      scheduledDateTime.millisecondsSinceEpoch % 1000000, // Unique ID
      'Hydration Reminder',
      message,
      tzScheduledDateTime,
      platformChannelSpecifies,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    /*print(
        "Scheduled notification at $scheduledDateTime with message: $message");*/
  }
}
