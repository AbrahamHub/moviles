import 'package:flutter/material.dart';
import 'package:tutorial/pages/spash_screen.dart';
import 'package:tutorial/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MySplashScreen(),
    );
  }
}
