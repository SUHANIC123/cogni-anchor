import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cogni_anchor/data/core/config/api_config.dart';
import 'package:cogni_anchor/data/core/pair_context.dart';
import 'package:cogni_anchor/data/profile/user_profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  static const String _userKey = 'user_session';
  static const String _onboardingKey = 'has_seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    developer.log('Onboarding marked as complete', name: 'AuthService');
  }

  Future<bool> tryAutoLogin() async {
    developer.log('Attempting auto-login', name: 'AuthService');
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_userKey)) {
      developer.log('No user session found', name: 'AuthService');
      return false;
    }

    try {
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        final data = jsonDecode(userStr);
        _currentUser = UserProfile.fromJson(data);

        if (_currentUser?.pairId != null) {
          PairContext.set(_currentUser!.pairId!);
        }
        developer.log('Auto-login successful for ${_currentUser?.email}', name: 'AuthService');
        return true;
      }
    } catch (e) {
      developer.log('Auto-login failed, signing out: $e', name: 'AuthService', error: e);
      await signOut();
    }
    return false;
  }

  Future<UserProfile> signIn(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/login');
    developer.log('Signing in user: $email', name: 'AuthService');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(data));

        if (_currentUser?.pairId != null) {
          PairContext.set(_currentUser!.pairId!);
        }

        developer.log('Sign in successful', name: 'AuthService');
        return _currentUser!;
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Login failed';
        developer.log('Sign in failed: $error', name: 'AuthService');
        throw Exception(error);
      }
    } catch (e) {
      developer.log('Sign in error: $e', name: 'AuthService', error: e);
      throw Exception('Login Error: $e');
    }
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/signup');
    developer.log('Signing up user: $email with role $role', name: 'AuthService');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        developer.log('Sign up successful', name: 'AuthService');
        return UserProfile.fromJson(data);
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Signup failed';
        developer.log('Sign up failed: $error', name: 'AuthService');
        throw Exception(error);
      }
    } catch (e) {
      developer.log('Sign up error: $e', name: 'AuthService', error: e);
      throw Exception('Signup Error: $e');
    }
  }

  Future<void> signOut() async {
    developer.log('Signing out', name: 'AuthService');
    _currentUser = null;
    PairContext.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> connectPatient(String pairCode, String caretakerId) async {
    developer.log('Connecting patient with pairCode: $pairCode', name: 'AuthService');
    
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/pairs/connect');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pair_code': pairCode,
        'caretaker_user_id': caretakerId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail']);
    }

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(pairId: pairCode);
      PairContext.set(pairCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      developer.log('Patient connected successfully', name: 'AuthService');
    }
  }
}