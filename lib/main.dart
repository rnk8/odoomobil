import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/odoo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './screens/task_list_screen.dart';
import '../services/fcm_service.dart';  // Importa tu servicio FCM

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Inicializa el servicio FCM
  final fcmService = FCMService();
  await fcmService.init();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? serverUrl = prefs.getString('serverUrl');
  String? email = prefs.getString('email');
  String? password = prefs.getString('password');

  if (serverUrl != null && email != null && password != null) {
    OdooService odooService = OdooService(
      baseUrl: serverUrl,
      username: email,
      password: password,
    );

  try {
        await odooService.authenticate();
        runApp(MyApp(odooService: odooService, fcmService: fcmService));
      } catch (e) {
        runApp(MyApp(fcmService: fcmService));  // Pasa solo fcmService
      }
    } else {
      runApp(MyApp(fcmService: fcmService));
    }
  }

class MyApp extends StatelessWidget {
  final OdooService? odooService;
  final FCMService fcmService;
  const MyApp({
    super.key,
    this.odooService,
    required this.fcmService,
  });
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Escolar',
      home: odooService != null 
          ? TaskListScreen(odooService: odooService!) 
          : LoginScreen(fcmService: fcmService),
    );
  }
}