import 'package:flutter/material.dart';
import 'screens/role_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint('BOOT: Firebase Initialized Successfully');
  } catch (e) {
    debugPrint('BOOT: Firebase initialization failed: $e');
  }
  runApp(const GymManagementApp());
}

class GymManagementApp extends StatelessWidget {
  const GymManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFA3E635);
    const darkBg = Color(0xFF0A0B0D);

    return MaterialApp(
      title: 'goJim Gym Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBg,
        primaryColor: limeColor,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: limeColor,
          secondary: Colors.cyan,
          background: darkBg,
          surface: const Color(0xFF14171D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1115),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Color(0xFFF3F4F6)),
          bodyMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Color(0xFF8E94A0)),
        ),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
