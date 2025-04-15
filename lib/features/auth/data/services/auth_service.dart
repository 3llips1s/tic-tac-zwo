import 'package:supabase_flutter/supabase_flutter.dart';

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
      print('error checking user existence: $error');
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
      print('OTP sign-in error: $error');
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
      print('User authenticated: ${response.user?.id}');
      return response;
    } catch (error) {
      print('OTP verification error: $error');
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
      print('Profile check error: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();
      return response;
    } catch (error) {
      print('error fetching user profile: $error');
      return null;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;
}
