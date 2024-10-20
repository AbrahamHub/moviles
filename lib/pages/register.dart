import 'package:flutter/material.dart';
import 'package:PhotoGuard/pages/sign_in.dart';
import 'package:PhotoGuard/utils/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign In

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [backgroundColor2, backgroundColor3, backgroundColor4],
          ),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              SizedBox(height: size.height * 0.03),
              Text(
                "¡Bienvenida/o!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 37,
                  color: textColor1,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Inicia sesión con tu cuenta de Google",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: textColor2, height: 1.2),
              ),
              SizedBox(height: size.height * 0.04),

              // Botón para registrarse con Google
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GestureDetector(
                  onTap: () async {
                    User? user = await signInWithGoogle();
                    if (user != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Usuario registrado con Google')),
                      );

                      // Después de registrar, navega a la página de Sign In
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignIn(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al iniciar sesión con Google')),
                      );
                    }
                  },
                  child: Container(
                    width: size.width,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.red, // Color para el botón de Google
                    ),
                    child: const Center(
                      child: Text(
                        "Iniciar sesión con Google",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 22),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.06),
              Text.rich(
                TextSpan(
                  text: "¿Ya eres miembro? ",
                  style: TextStyle(
                    color: textColor2,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: "Inicia sesión",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignIn(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // El usuario canceló el inicio de sesión.

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user; // Devuelve el usuario autenticado
    } catch (e) {
      print(e); // Manejar errores de autenticación
      return null;
    }
  }
}
