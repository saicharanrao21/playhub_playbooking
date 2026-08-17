import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interface.dart';
import 'auth_state.dart';
import '../../app/bootstrap/bootstrap.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState.initializing()) {
    _init();
  }

  void _init() {
    final identity = _authRepository.getCurrentIdentity();
    if (identity != null) {
      state = AuthState.authenticated(identity);
    } else {
      state = const AuthState.unauthenticated();
    }

    _authRepository.identityChanges.listen((identity) {
      if (identity != null) {
        state = AuthState.authenticated(identity);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.authenticating();
    try {
      final identity = await _authRepository.login(email, password);
      if (identity != null) {
        state = AuthState.authenticated(identity);
      } else {
        state = const AuthState.error('Invalid email or password');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState.unauthenticated();
  }
}
