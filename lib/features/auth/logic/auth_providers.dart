import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tic_tac_zwo/features/auth/data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) {
    return AuthService();
  },
);

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authStateAsync = ref.watch(authStateChangesProvider);
  return authStateAsync.maybeWhen(
    data: (authState) => authState.session?.user.id,
    orElse: () => null,
  );
});
