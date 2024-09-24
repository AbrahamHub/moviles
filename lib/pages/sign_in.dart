import 'package:flutter/material.dart';
import 'package:tutorial/utils/colors.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

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
            SizedBox(
              height: size.height * 0.03,
            ),
            Text(
              "Hello Again",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 37,
                color: textColor1,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              "Welcome back",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: textColor2, height: 1.2),
            ),
            SizedBox(
              height: size.height * 0.04,
            ),
            //Username and password Inputs
            myTextInput("Enter username", Colors.white),
            myTextInput("Password", Colors.black26),
            const SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Recovery Password    ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor2,
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Container myTextInput(String hint, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 10,
      ),
      child: TextField(
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 22,
            ),
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
            )),
      ),
    );
  }
}
