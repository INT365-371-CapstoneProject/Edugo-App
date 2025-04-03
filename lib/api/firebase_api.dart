import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    // ขออนุญาตการแจ้งเตือน
    await _firebaseMessaging.requestPermission();

    // รับ FCM Token
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token:$fCMToken');

    // เมื่อแอปทำงานอยู่ใน foreground รับข้อความ
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.title}');
      // ทำสิ่งที่คุณต้องการเมื่อได้รับข้อความจาก FCM เช่น แสดงแจ้งเตือนภายในแอป
    });

    // เมื่อผู้ใช้คลิกที่การแจ้งเตือนและเปิดแอปขึ้นมา
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked! ${message.notification?.title}');
      // ทำสิ่งที่คุณต้องการเมื่อผู้ใช้คลิกที่การแจ้งเตือน
    });
  }
}
