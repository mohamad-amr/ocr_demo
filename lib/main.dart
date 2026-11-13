import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/ocr_cubit.dart';
import 'services/ocr_service.dart';
import 'views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OcrCubit(MockOcrService()),
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
