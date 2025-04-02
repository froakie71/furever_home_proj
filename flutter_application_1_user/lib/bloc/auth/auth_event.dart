import 'dart:io';

abstract class AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final Map<String, dynamic> userData;
  final File? imageFile;

  SignUpRequested({
    required this.email,
    required this.password,
    required this.userData,
    this.imageFile,
  });
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested(this.email, this.password);
}

class SignOutRequested extends AuthEvent {}
