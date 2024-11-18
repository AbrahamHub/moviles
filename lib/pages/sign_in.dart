import 'package:flutter/material.dart';
import 'package:PhotoGuard/pages/register.dart';
import 'package:PhotoGuard/pages/home.dart';
import 'package:PhotoGuard/utils/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

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
              _buildInputFields(usernameController, passwordController),
              const SizedBox(height: 10),
              _buildRecoveryPassword(),
              SizedBox(height: size.height * 0.04),
              _buildSignInButton(context, usernameController, passwordController),
              SizedBox(height: size.height * 0.06),
              _buildDivider(size),
              SizedBox(height: size.height * 0.06),
              _buildSocialLogin(context),
              SizedBox(height: size.height * 0.07),
              _buildRegisterPrompt(context),
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
          "¡Hola de nuevo!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 37,
            color: textColor1,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "Bienvenida/o de regreso",
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

  Widget _buildInputFields(
      TextEditingController usernameController, TextEditingController passwordController) {
    return Column(
      children: [
        myTextInput("Correo electrónico", Colors.white, usernameController),
        myTextInput("Contraseña", Colors.black26, passwordController, isObscure: true),
      ],
    );
  }

  Widget _buildRecoveryPassword() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        "Contraseña de Recuperación",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: textColor2,
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context,
      TextEditingController usernameController, TextEditingController passwordController) {
    return GestureDetector(
      onTap: () async {
        final String email = usernameController.text.trim();
        final String password = passwordController.text.trim();

        if (email.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, llena todos los campos')),
          );
          return;
        }

        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bienvenido, ${userCredential.user!.email}!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          if (e.code == 'user-not-found') {
            errorMessage = 'No existe ningún usuario con ese correo.';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'La contraseña es incorrecta.';
          } else {
            errorMessage = 'Error al iniciar sesión. Intenta nuevamente.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: buttonColor,
        ),
        child: const Center(
          child: Text(
            "Iniciar Sesión",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
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
          "  O ingresa con  ",
          style: TextStyle(
              color: Color(0xff6F6B7A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Container(
          height: 2,
          width: size.width * 0.25,
          color: Colors.black12,
        ),
      ],
    );
  }

  Widget _buildSocialLogin(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () async {
                User? user = await signInWithGoogle();
                if (user != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bienvenido, ${user.displayName}!')),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al iniciar sesión con Google')),
                  );
                }
              },
              child: socialIcon("assets/images/google.png", "Google"),
            ),
            socialIcon("assets/images/microsoft.png", "Microsoft"),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterPrompt(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: "¿Aún no eres miembro?  ",
        style: TextStyle(
          color: textColor2,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        children: [
          TextSpan(
            text: "Regístrate",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  RegisterPage()),
                );
              },
          ),
        ],
      ),
    );
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
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
