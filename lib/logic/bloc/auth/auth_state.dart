import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/data/profile/user_profile.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserProfile user;
  final UserModel role;
  final bool hasSeenOnboarding;

  AuthAuthenticated({
    required this.user,
    required this.role,
    this.hasSeenOnboarding = false,
  });
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
