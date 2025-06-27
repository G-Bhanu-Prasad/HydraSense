import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/ble_helper.dart';

class MyTaskHandler extends TaskHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      await BLEHelper.autoReconnectToLastDevice(context);
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      await BLEHelper.autoReconnectToLastDevice(context);
    }

    FlutterForegroundTask.updateService(
      notificationTitle: 'HydraSense Background Task',
      notificationText: 'Maintaining Bluetooth Connection...',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
