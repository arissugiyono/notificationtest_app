import 'package:fcm_app/firebase_options.dart';
import 'package:fcm_app/pushNotif.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

// 1. PINDAHKAN INI KE LUAR CLASS (Top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FirebaseMessaging _messaging;
  late int _totalNotifications; 
  PushNotif? _notificationInfo;

  // 2. JADIKAN METHOD CLASS (Sejajar dengan initState)
  void registrasiNotif() async {
    _messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          setState(() {
            _notificationInfo = PushNotif(
              title: message.notification?.title,
              body: message.notification?.body,
              dataBody: message.data['body'],
              dataTitle: message.data['title'],
            );
            _totalNotifications++;
          });

          if (_notificationInfo != null) {
            showSimpleNotification(
              Text(_notificationInfo!.title ?? ''),
              leading: const Icon(Icons.notifications),
              subtitle: Text(_notificationInfo!.body ?? ''),
              background: Colors.cyan.shade700,
              duration: const Duration(seconds: 5),
            );
          }
        }
      });
    }
  }

  // 3. KELUARKAN DARI registrasiNotif() AGAR BISA DIPANGGIL DI initState
  void checkForInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      setState(() {
        _notificationInfo = PushNotif(
          title: initialMessage.notification?.title,
          body: initialMessage.notification?.body,
          dataTitle: initialMessage.data['title'],
          dataBody: initialMessage.data['body'],
        );
        _totalNotifications++;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _totalNotifications = 0; // Inisialisasi variabel

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {
        _notificationInfo = PushNotif(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );
        _totalNotifications++;
      });
    });

  
    registrasiNotif();
    checkForInitialMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total Notifications: $_totalNotifications'),
            if (_notificationInfo != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${_notificationInfo!.dataTitle ?? _notificationInfo!.title}"),
                      Text("${_notificationInfo!.dataBody ?? _notificationInfo!.body}"),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
