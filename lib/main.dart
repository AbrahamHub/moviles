import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:PhotoGuard/pages/home.dart';
import 'package:PhotoGuard/pages/spash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/config/.env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Gestiona la navegación basada en el estado de autenticación
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Si el estado está cargándose, muestra un indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hay un usuario autenticado, redirige a HomePage
          if (snapshot.hasData) {
            return const HomePage(); // Redirige al Home
          }

          // Si no hay usuario autenticado, muestra la pantalla inicial (Splash/Login)
          return const MySplashScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomePage(),
        '/splash': (context) => const MySplashScreen(),
      },
    );
  }
}
