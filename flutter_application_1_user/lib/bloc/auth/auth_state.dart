abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {}

class UnAuthenticated extends AuthState {}

class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}
