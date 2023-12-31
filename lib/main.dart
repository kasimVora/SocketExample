import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:pdfdemo/Screen/ApiClient.dart';
import 'package:pdfdemo/SocketHelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Helper.dart';
import 'Model/UserModel.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'Screen/CallingScreen.dart';
import 'Screen/HomeScreen.dart';
import 'Screen/LoginScreen.dart';
import 'Screen/NotificationService.dart';
import 'Screen/SignUp.dart';
import 'Screen/SplashScreen.dart';
import 'firebase_options.dart';

final userRef = FirebaseFirestore.instance.collection('user');
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FirebaseAuth authInst = FirebaseAuth.instance;
FirebaseMessaging messaging = FirebaseMessaging.instance;
final service = FlutterBackgroundService();
String socketId= "";
const appId = "53d1bde7af10469f858cfafdcb561a57";
const appCertificate = "e0acdc5d4cec48f28ea17fb702ddeada";
NotificationService notificationService = NotificationService();
UserModel? createdUser;
late DioClient client;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await notificationService.init();
  await notificationService.requestIOSPermissions();
  await notificationService.cancelAllNotifications();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then((value) async{
    await Permission.scheduleExactAlarm.request();
    initializeService().whenComplete(() async{
        service.startService();
    });

  });

  client = DioClient();


  // if(authInst.currentUser!=null){
  //   userRef.doc(authInst.currentUser!.uid).snapshots().listen((querySnapshot) {
  //
  //     String field =querySnapshot.get("caller");
  //     if(field!=""){
  //      Navigator.push(navigatorKey.currentState!.context, MaterialPageRoute(builder: (context) =>  CallingScreen( token: field.split(",")[0], channel: field.split(",")[1], isHost: false,)));
  //     }
  //   });
  //
  // }


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen()
    );
  }
}

Future<void> initializeService() async {




  await service.configure(
    androidConfiguration: AndroidConfiguration(

      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,
      // auto start service
      autoStart: true,
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
      autoStartOnBoot: true
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}


Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();


  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
      print('setAsForeground');
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
      print('setAsBackground');
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

    SocketHelper().initSocket();


    service.on('make_call').listen((event) {
      SocketHelper().socket!.emit('calling',event);
      service.invoke("HomeScreen_Callback",event);
    });


  SocketHelper().socket!.on('incoming_call_event', (data) {
    notificationService.showNotification(444, "Incoming Call","test",jsonEncode(data));
    // Navigator.push(navigatorKey.currentContext!, MaterialPageRoute(builder: (_) =>  CallingScreen( token: data['token'], channel: data['chanel_name'], isHost: false,)));
  });
}
