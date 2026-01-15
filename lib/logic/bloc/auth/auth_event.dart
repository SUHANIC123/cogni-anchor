
abstract class AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthSignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;

  AuthSignupRequested({
    required this.email,
    required this.password,
    required this.role,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthOnboardingCompleted extends AuthEvent {}
