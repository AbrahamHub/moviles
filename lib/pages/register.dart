import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:PhotoGuard/pages/home.dart';
import 'package:PhotoGuard/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  RegisterPage({super.key});

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
            padding: const EdgeInsets.symmetric(horizontal: 25),
            children: [
              SizedBox(height: size.height * 0.03),
              _buildTitle(),
              SizedBox(height: size.height * 0.04),
              _buildInputFields(),
              SizedBox(height: size.height * 0.04),
              _buildRegisterButton(context),
              SizedBox(height: size.height * 0.06),
              _buildDivider(size),
              SizedBox(height: size.height * 0.06),
              _buildGoogleLoginButton(context),
              SizedBox(height: size.height * 0.07),
              _buildLoginPrompt(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
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
          "Únete a nosotros con una cuenta nueva",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            color: textColor2,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        myTextInput("Correo electrónico", Colors.white, emailController),
        myTextInput("Contraseña", Colors.black26, passwordController, isObscure: true),
        myTextInput("Confirmar Contraseña", Colors.black26, confirmPasswordController, isObscure: true),
      ],
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final String email = emailController.text.trim();
        final String password = passwordController.text.trim();
        final String confirmPassword = confirmPasswordController.text.trim();

        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(email)) {
          _showSnackBar(context, 'Introduce un correo válido');
          return;
        }

        final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
        if (!passwordRegex.hasMatch(password)) {
          _showSnackBar(context, 'La contraseña debe tener al menos 8 caracteres, incluyendo un número');
          return;
        }

        if (password != confirmPassword) {
          _showSnackBar(context, 'Las contraseñas no coinciden');
          return;
        }

        try {
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': email,
            'provider': 'Email',
          });

          _navigateToHome(context);
        } on FirebaseAuthException catch (e) {
          _showSnackBar(context, 'Error: ${e.message}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.redAccent,
        ),
        child: const Center(
          child: Text(
            "Registrarse",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 2,
          width: size.width * 0.25,
          color: Colors.black12,
        ),
        const Text(
          "  O continúa con:  ",
          style: TextStyle(
            color: Color(0xff6F6B7A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Container(
          height: 2,
          width: size.width * 0.25,
          color: Colors.black12,
        ),
      ],
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) return;

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': userCredential.user!.email,
            'provider': 'Google',
          });

          _navigateToHome(context);
        } catch (e) {
          _showSnackBar(context, 'Error al iniciar sesión con Google: ${e.toString()}');
        }
      },
      child: socialIcon("assets/images/google.png", "Iniciar con Google"),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: "¿Ya eres miembro?  ",
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
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pop(context);
              },
          ),
        ],
      ),
    );
  }

  Widget socialIcon(String imagePath, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Image.asset(imagePath, height: 40),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor2,
          ),
        ),
      ],
    );
  }

  Container myTextInput(String hint, Color color, TextEditingController controller,
      {bool isObscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 19),
        ),
      ),
    );
  }
}
