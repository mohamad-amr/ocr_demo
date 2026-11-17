import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/ocr_cubit.dart';
import 'services/ocr_service.dart';
import 'services/firebase_setup.dart';
import 'services/gemini_ocr_service.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeFirebaseAI();
    runApp(MyApp(service: GeminiOcrService()));
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Firebase setup needs attention',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Check docs/firebase-ai-logic.md for platform configuration and App Check setup. For release web builds, set RECAPTCHA_ENTERPRISE_SITE_KEY.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: main,
                      child: const Text('Retry setup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.service});
  final OcrService service;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OcrCubit(service),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MathLens | AI math workspace',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Geist',
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF090909),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFA78BFA),
            onPrimary: Color(0xFF090909),
            surface: Color(0xFF111111),
            onSurface: Color(0xFFFFFFFF),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Colors.black,
            contentTextStyle: TextStyle(color: Colors.white),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: const HomeView(),
      ),
    );
  }
}
