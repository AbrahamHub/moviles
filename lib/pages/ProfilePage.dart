import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Asegúrate de incluir esta dependencia
import 'package:PhotoGuard/models/User.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserModel _userModel;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Inicializa GoogleSignIn

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Cargar el usuario actual desde FirebaseAuth
  void _loadUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userModel = UserModel.fromFirebaseUser(user);
    }
  }

  // Cerrar sesión de Firebase y Google
  Future<void> _signOut() async {
    try {
      // Cerrar sesión de Google si está conectado
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      // Cerrar sesión de Firebase
      await FirebaseAuth.instance.signOut();
      // Redirigir a la pantalla inicial (Splash/Login)
      Navigator.of(context).pushReplacementNamed('/splash');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  // Mostrar un cuadro de diálogo para confirmar el cierre de sesión
  Future<bool> _showSignOutDialog() async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Devuelve false
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Devuelve true
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    )) ??
        false; // Devuelve false si el resultado es null
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Usuario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'UID: ${_userModel.uid}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Correo: ${_userModel.email ?? "No disponible"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // Color del botón
                ),
                onPressed: () async {
                  final shouldSignOut = await _showSignOutDialog();
                  if (shouldSignOut) {
                    _signOut();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
