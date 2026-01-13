import 'package:firebase_auth/firebase_auth.dart';

class NewUserException implements Exception {
  final User? user;
  NewUserException(this.user);
  
  @override
  String toString() => 'NewUserException: User ${user?.uid} is new and needs to complete registration.';
}
