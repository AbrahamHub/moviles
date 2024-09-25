import 'package:flutter/material.dart';
import 'package:tutorial/pages/sign_in.dart';
import 'package:tutorial/utils/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:tutorial/database/user_db.dart'; // Import UserDB
import 'package:tutorial/models/user.dart'; // Import User model

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final TextEditingController usernameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

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
                "Únete a nosotros con una cuenta nueva",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: textColor2, height: 1.2),
              ),
              SizedBox(height: size.height * 0.04),
              myTextInput("Nombre de Usuario", Colors.white, usernameController),
              myTextInput("Correo electrónico", Colors.white, emailController),
              myTextInput("Contraseña", Colors.black26, passwordController, isObscure: true),
              myTextInput("Confirmar Contraseña", Colors.black26, confirmPasswordController, isObscure: true),
              const SizedBox(height: 10),
              SizedBox(height: size.height * 0.04),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        // Handle registration logic
                        if (passwordController.text == confirmPasswordController.text) {
                          final userDB = UserDB();
                          await userDB.create(
                            username: usernameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Usuario registrado con éxito')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Las contraseñas no coinciden')),
                          );
                        }
                      },
                      child: Container(
                        width: size.width,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: buttonColor,
                        ),
                        child: const Center(
                          child: Text(
                            "Registrarse",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 22),
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
            ],
          ),
        ),
      ),
    );
  }

  Container myTextInput(String hint, Color color, TextEditingController controller, {bool isObscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: TextField(
        controller: controller, // Set controller
        obscureText: isObscure, // Handle obscurity
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black45,
            fontSize: 19,
          ),
          suffixIcon: Icon(
            Icons.visibility_off_outlined,
            color: color,
          ),
        ),
      ),
    );
  }
}
