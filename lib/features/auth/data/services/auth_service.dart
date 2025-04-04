import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Checks if a user with the given email exists
  Future<bool> checkUserExists(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      // If no exception is thrown, user exists
      return true;
    } catch (error) {
      if (error is AuthException && error.message.contains('Email not found')) {
        return false;
      }
      // For other errors, log and assume user might exist
      print('Error checking user existence: $error');
      return false;
    }
  }

  /// Universal method to send OTP regardless of whether user exists
  /// Returns true if OTP was sent successfully
  Future<bool> sendOTP(String email) async {
    try {
      // For both new and existing users, we use signInWithOtp
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.ticTacZwo://login-callback/',
      );
      return true;
    } catch (error) {
      print('OTP sending error: $error');
      throw Exception('Failed to send verification code: $error');
    }
  }

  /// Initiates email OTP sign-in flow
  /// Returns true if OTP was sent successfully
  Future<bool> signInWithOTP(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.ticTacZwo://login-callback/',
      );
      return true;
    } catch (error) {
      print('OTP sign-in error: $error');
      return false;
    }
  }

  /// Verifies OTP for authentication
  Future<AuthResponse?> verifyOTP(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.magiclink,
      );
      print('User authenticated: ${response.user?.id}');
      return response;
    } catch (error) {
      print('OTP verification error: $error');
      return null;
    }
  }

  /// Initiates email OTP sign-up flow
  /// Returns true if OTP was sent successfully
  Future<bool> signUpWithOTP(String email) async {
    try {
      // Check if user exists first
      bool exists = await checkUserExists(email);
      if (exists) {
        print('User already exists with this email');
        return false;
      }

      // If user doesn't exist, proceed with OTP sign-up
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.ticTacZwo://signup-callback/',
      );
      return true;
    } catch (error) {
      print('OTP sign-up error: $error');
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
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

  /// Checks if the user has completed their profile
  /// Call this after successful authentication
  Future<bool> hasUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Using .maybeSingle() instead of .single() to avoid exceptions
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Simply return whether response is not null
      return response != null;
    } catch (error) {
      print('Profile check error: $error');
      return false;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;
}
