
import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const HanziCardApp());
}

class HanziCardApp extends StatelessWidget {
  const HanziCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '汉字卡片',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default font
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
