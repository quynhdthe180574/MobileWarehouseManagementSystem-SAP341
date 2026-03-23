import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const SapStockApp());
}

class SapStockApp extends StatelessWidget {
  const SapStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAP Stock Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
