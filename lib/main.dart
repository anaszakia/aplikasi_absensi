import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahkan import ini
import 'pages/login_page.dart';

// GlobalKey sudah ada dan benar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Tambahkan async
  // Tambahkan inisialisasi binding
  WidgetsFlutterBinding.ensureInitialized();

  // Opsional: set orientasi (jika diperlukan)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
      navigatorKey: navigatorKey, // Ini sudah benar
    );
  }
}
