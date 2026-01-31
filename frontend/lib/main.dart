import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_fonts/google_fonts.dart';
import 'styles/app_colors.dart'; 
import 'pages/auth_page.dart'; 
import 'pages/dahboard_page.dart';


void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Customer Support Intelligence Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.robotoTextTheme()
            .apply(displayColor: Colors.black, bodyColor: AppColors.textColor)
            .copyWith(
              displayLarge: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              displayMedium: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              bodyMedium: const TextStyle(fontSize: 16),
              bodySmall: const TextStyle(
                fontSize: 14,
                color: Color.fromRGBO(74, 74, 74, 0.8),
              ),
            ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
