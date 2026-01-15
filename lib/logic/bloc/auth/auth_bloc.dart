import 'dart:async';
import 'dart:developer' as developer;
import 'package:cogni_anchor/data/auth/auth_service.dart';
import 'package:cogni_anchor/data/auth/user_model.dart';
import 'package:cogni_anchor/data/notification/fcm_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cogni_anchor/logic/bloc/auth/auth_event.dart';
import 'package:cogni_anchor/logic/bloc/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final FCMService _fcmService;

  AuthBloc({AuthService? authService, FCMService? fcmService})
      : _authService = authService ?? AuthService.instance,
        _fcmService = fcmService ?? FCMService.instance,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignupRequested>(_onSignup);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Checking auth status', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      final isLoggedIn = await _authService.tryAutoLogin();

      if (isLoggedIn && _authService.currentUser != null) {
        developer.log('User logged in, initializing FCM', name: 'AuthBloc');
        try {
          await _fcmService.initialize();
        } catch (e) {
          developer.log('FCM Init Error: $e', name: 'AuthBloc', error: e);
        }

        final hasSeenOnboarding = await _authService.hasSeenOnboarding();
        final role = _mapRole(_authService.currentUser!.role);

        developer.log('User restored: ${_authService.currentUser!.email}, Role: $role', name: 'AuthBloc');
        emit(AuthAuthenticated(
          user: _authService.currentUser!,
          role: role,
          hasSeenOnboarding: hasSeenOnboarding,
        ));
      } else {
        developer.log('User not logged in', name: 'AuthBloc');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      developer.log('Auth check failed: $e', name: 'AuthBloc', error: e);
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Login requested for ${event.email}', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      final user = await _authService.signIn(event.email, event.password);

      developer.log('Login successful, initializing FCM', name: 'AuthBloc');
      try {
        await _fcmService.initialize();
      } catch (e) {
        developer.log('FCM Init Error: $e', name: 'AuthBloc', error: e);
      }

      final hasSeenOnboarding = await _authService.hasSeenOnboarding();
      final role = _mapRole(user.role);

      emit(AuthAuthenticated(
        user: user,
        role: role,
        hasSeenOnboarding: hasSeenOnboarding,
      ));
    } catch (e) {
      developer.log('Login failed: $e', name: 'AuthBloc', error: e);
      emit(AuthError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onSignup(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Signup requested for ${event.email}', name: 'AuthBloc');
    emit(AuthLoading());
    try {
      final user = await _authService.signUp(
        email: event.email,
        password: event.password,
        role: event.role,
      );

      developer.log('Signup successful, initializing FCM', name: 'AuthBloc');
      try {
        await _fcmService.initialize();
      } catch (e) {
        developer.log('FCM Init Error: $e', name: 'AuthBloc', error: e);
      }

      final role = _mapRole(user.role);
      emit(AuthAuthenticated(
        user: user,
        role: role,
        hasSeenOnboarding: false,
      ));
    } catch (e) {
      developer.log('Signup failed: $e', name: 'AuthBloc', error: e);
      emit(AuthError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Logout requested', name: 'AuthBloc');
    emit(AuthLoading());
    await _authService.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      developer.log('Onboarding completed', name: 'AuthBloc');
      await _authService.completeOnboarding();
      final currState = state as AuthAuthenticated;
      emit(AuthAuthenticated(
        user: currState.user,
        role: currState.role,
        hasSeenOnboarding: true,
      ));
    }
  }

  UserModel _mapRole(String role) {
    return role.toLowerCase() == 'patient' ? UserModel.patient : UserModel.caretaker;
  }
}
