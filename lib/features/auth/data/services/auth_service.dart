import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/data/models/user_profile.dart';
import '../../../profile/logic/user_profile_providers.dart';

class AuthException implements Exception {
  final String message;
  final dynamic originalError;

  AuthException(this.message, [this.originalError]);

  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check if a user with the given email exists
  Future<bool> checkUserExists(String email) async {
    try {
      final response = await _supabase
          .rpc('check_user_exists', params: {'email_to_check': email});
      return response as bool;
    } catch (error) {
      developer.log('error checking user existence: $error',
          name: 'auth_service');
      return false;
    }
  }

  // Initiates email OTP sign-in flow
  Future<bool> signInWithOTP(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      return true;
    } catch (error) {
      developer.log('OTP sign-in error: $error', name: 'auth_service');
      return false;
    }
  }

  // Verifies OTP for authentication
  Future<AuthResponse?> verifyOTP(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      developer.log('User authenticated: ${response.user?.id}',
          name: 'auth_service');
      return response;
    } catch (error) {
      developer.log('OTP verification error: $error', name: 'auth_service');
      return null;
    }
  }

  // Returns true if OTP was sent successfully
  Future<bool> signUpWithOTP(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      return true;
    } catch (error) {
      developer.log('OTP sign-up error: $error', name: 'auth_service');
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();

    await clearCachedUserProfile();
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.ticTacZwo://login-callback/',
    );
  }

  Future<void> signInWithApple() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.ticTacZwo://login-callback/',
    );
  }

  // Checks if the user has completed their profile
  // Call this after successful authentication
  Future<bool> hasUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Using .maybeSingle() instead of .single() to avoid exceptions
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      // Simply return whether response is not null
      return response != null;
    } catch (error) {
      developer.log('Profile check error: $error', name: 'auth_service');
      return false;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase.from('users').select().eq('id', user.id).single();

      return UserProfile.fromJson(response);
    } catch (e) {
      developer.log('failed to get user profile: $e', name: 'auth_service');
      return null;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;
}
