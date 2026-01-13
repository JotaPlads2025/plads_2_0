import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initializeLocalNotifications();
  }

  void _initializeLocalNotifications() async {
    tz.initializeTimeZones();
    
    // Android Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS Settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  // --- FIRESTORE NOTIFICATIONS (In-App) ---

  // Send Notification (e.g., from Logic)
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      final docRef = _db.collection('notifications').doc();
      final notification = NotificationModel(
        id: docRef.id,
        userId: recipientId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        createdAt: DateTime.now(),
      );

      await docRef.set(notification.toMap());
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Stream of Notifications for a User
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to last 50
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  // Mark as Read
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // --- LOCAL NOTIFICATIONS (Reminders) ---

  // Schedule a reminder 1 hour before class
  Future<void> scheduleClassReminder({
    required int id, // Unique Integer ID for Local Notifications
    required String title,
    required String body,
    required DateTime classTime,
  }) async {
    final scheduledDate = classTime.subtract(const Duration(hours: 1));
    
    if (scheduledDate.isBefore(DateTime.now())) return; // Don't schedule if already passed

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminders',
          'Recordatorios de Clase',
          channelDescription: 'Avisos 1 hora antes de la clase',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation removed based on compilation error
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
