import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? name;
  final String? email;

  UserModel({required this.uid, this.name, this.email});

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      name: user.displayName,
      email: user.email,
    );
  }
}
