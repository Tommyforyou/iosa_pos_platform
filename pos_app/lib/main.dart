import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(size: Size(1600, 950), minimumSize: Size(1200, 800), center: true, title: 'IOSA POS 2026 V1.0');

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    //await windowManager.maximize();
    await windowManager.focus();
  });

  runApp(const IOSAPOSApp());
}

class IOSAPOSApp extends StatelessWidget {
  const IOSAPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
