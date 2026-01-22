import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static Future<void> init() async {
    tz.initializeTimeZones();

    await AwesomeNotifications().initialize(
      null, 
      [
        // 1. ALARM CHANNEL - High priority, rings loudly
        NotificationChannel(
          channelGroupKey: 'tools_channel_group',
          channelKey: 'tools_channel',
          channelName: 'Alarms & Timers',
          channelDescription: 'High priority alarms that ring loudly',
          defaultColor: const Color(0xFF00D2D3),
          importance: NotificationImportance.Max,
          playSound: true, 
          enableVibration: true,
          criticalAlerts: true, // Required here for DND bypass
          onlyAlertOnce: false,
        ),
        // 2. CALENDAR CHANNEL - For deadlines
        NotificationChannel(
          channelGroupKey: 'schedule_channel_group',
          channelKey: 'calendar_channel',
          channelName: 'Calendar Events',
          channelDescription: 'Scheduled agenda items',
          defaultColor: const Color(0xFF6C63FF),
          importance: NotificationImportance.High,
          playSound: true,
        ),
        // 3. ENGAGEMENT CHANNEL - For summaries and streaks
        NotificationChannel(
          channelGroupKey: 'engagement_channel_group',
          channelKey: 'engagement_channel',
          channelName: 'Astra Uplink',
          channelDescription: 'Daily briefings and engagement alerts',
          defaultColor: const Color(0xFFFFD700),
          importance: NotificationImportance.High,
          playSound: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(channelGroupKey: 'tools_channel_group', channelGroupName: 'Tools'),
        NotificationChannelGroup(channelGroupKey: 'schedule_channel_group', channelGroupName: 'Schedule'),
        NotificationChannelGroup(channelGroupKey: 'engagement_channel_group', channelGroupName: 'Engagement'),
      ],
      debug: true,
    );

    // Request permissions on startup
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // --- CLOCK SCREEN: ALARM ---
  static Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'tools_channel',
        title: '⏰ $title',
        body: body,
        category: NotificationCategory.Alarm, 
        wakeUpScreen: true,                   
        fullScreenIntent: true,               
        autoDismissible: false,
        // Removed criticalAlerts from here (it belongs in the Channel)
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledTime,
        preciseAlarm: true,   
        allowWhileIdle: true, 
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS', 
          label: 'Dismiss Mission', 
          actionType: ActionType.DismissAction
        ),
      ],
    );
  }

  // --- CALENDAR SCREEN: DEADLINES ---
  static Future<void> scheduleDeadlineNotification({
    required int id,
    required String title,
    required DateTime date,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'calendar_channel',
        title: '📅 Deadline: $title',
        body: 'Scheduled for ${DateFormat('HH:mm').format(date)}',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: date),
    );
  }

  // --- PROFILE SCREEN: ENGAGEMENT ---
  static Future<void> scheduleDailySummary(TimeOfDay time) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 888,
        channelKey: 'engagement_channel',
        title: '☀️ Daily Briefing',
        body: 'Commander, your tasks and stats are ready.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: time.hour, 
        minute: time.minute, 
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> scheduleTrainingReminders(TimeOfDay t1, TimeOfDay t2) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 701, 
        channelKey: 'engagement_channel', 
        title: '⚡ Training 1', 
        body: 'XP Time! Let\'s get moving.'
      ),
      schedule: NotificationCalendar(hour: t1.hour, minute: t1.minute, repeats: true),
    );
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 702, 
        channelKey: 'engagement_channel', 
        title: '🔥 Training 2', 
        body: 'Finish the day strong!'
      ),
      schedule: NotificationCalendar(hour: t2.hour, minute: t2.minute, repeats: true),
    );
  }

  static Future<void> resetStreakProtection() async {
    await AwesomeNotifications().cancel(666);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 666, 
        channelKey: 'engagement_channel', 
        title: 'Astra is waiting', 
        body: '24h streak warning! Don\'t lose your progress.'
      ),
      schedule: NotificationCalendar.fromDate(
        date: DateTime.now().add(const Duration(hours: 24)),
        allowWhileIdle: true,
      ),
    );
  }

  // --- UTILITIES ---
  static Future<void> cancelAll() async => await AwesomeNotifications().cancelAll();
  
  static Future<void> cancelNotification(int id) async => await AwesomeNotifications().cancel(id);
}