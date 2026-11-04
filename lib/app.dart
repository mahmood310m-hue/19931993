import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'main.dart' show supabaseConfigured;
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class KautharApp extends StatelessWidget {
  const KautharApp({super.key});

  @override
  Widget build(BuildContext context) {
    final configured = supabaseConfigured;
    return MaterialApp(
      title: 'مدرسة كوثر الأهلية المختلطة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF75BDA7),
          surface: const Color(0xFFF6FAF8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6FAF8),
        textTheme: GoogleFonts.tajawalTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6FAF8),
          foregroundColor: Color(0xFF24483D),
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F8F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: !configured
          ? const _SetupRequired()
          : StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              builder: (context, snapshot) {
                final session = Supabase.instance.client.auth.currentSession;
                return session == null ? const LoginScreen() : const HomeScreen();
              },
            ),
    );
  }
}

class _SetupRequired extends StatelessWidget {
  const _SetupRequired();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.school_rounded, size: 64, color: Color(0xFF75BDA7)),
          const SizedBox(height: 16),
          const Text('مدرسة كوثر الأهلية المختلطة',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('يلزم إعداد SUPABASE_URL و SUPABASE_ANON_KEY قبل تشغيل التطبيق.',
            textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
