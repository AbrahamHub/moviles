import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/splash');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  Future<bool> _showSignOutDialog() async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    )) ??
        false;
  }

  String _getGravatarUrl(String email) {
    final emailBytes = utf8.encode(email.toLowerCase().trim());
    final hash = md5.convert(emailBytes);
    return 'https://www.gravatar.com/avatar/$hash?d=identicon';
  }

  @override
  Widget build(BuildContext context) {
    final gravatarUrl = userEmail != null ? _getGravatarUrl(userEmail!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (gravatarUrl != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(gravatarUrl),
                  radius: 50,
                )
              else
                const CircleAvatar(
                  child: Icon(Icons.person, size: 50),
                  radius: 50,
                ),
              const SizedBox(height: 16),
              Text(
                'Correo: ${userEmail ?? "No disponible"}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white), // Cambiar color del texto
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: () async {
                  final shouldSignOut = await _showSignOutDialog();
                  if (shouldSignOut) {
                    _signOut();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
