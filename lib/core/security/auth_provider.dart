import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interface.dart';
import 'auth_state.dart';
import 'token_storage.dart';
import '../models/auth_models.dart';
import '../models/app_models.dart';
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

/// Provider for the currently active organization context.
final activeOrganizationProvider = StateNotifierProvider<ActiveOrganizationNotifier, String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ActiveOrganizationNotifier(authState, tokenStorage);
});

class ActiveOrganizationNotifier extends StateNotifier<String?> {
  final AuthState _authState;
  final TokenStorage _tokenStorage;

  ActiveOrganizationNotifier(this._authState, this._tokenStorage) : super(null) {
    _resolveActiveOrganization();
  }

  Future<void> _resolveActiveOrganization() async {
    final identity = _authState.identity;
    if (identity == null) {
      state = null;
      return;
    }

    final memberships = identity.memberships;
    if (memberships.isEmpty) {
      state = null;
      return;
    }

    // 1. Try to restore from persistence
    final storedOrgId = await _tokenStorage.readActiveOrgId();
    if (storedOrgId != null) {
      final stillMember = memberships.any((m) => m.organizationId == storedOrgId);
      if (stillMember) {
        state = storedOrgId;
        return;
      }
    }

    // 2. Deterministic fallback
    // If exactly one membership, select it
    if (memberships.length == 1) {
      final orgId = memberships.first.organizationId;
      state = orgId;
      await _tokenStorage.saveActiveOrgId(orgId);
      return;
    }

    // 3. Fallback to first membership in list
    final firstOrgId = memberships.first.organizationId;
    state = firstOrgId;
    await _tokenStorage.saveActiveOrgId(firstOrgId);
  }

  Future<void> selectOrganization(String orgId) async {
    final identity = _authState.identity;
    if (identity == null) return;

    final isMember = identity.memberships.any((m) => m.organizationId == orgId);
    if (isMember) {
      state = orgId;
      await _tokenStorage.saveActiveOrgId(orgId);
    }
  }
}

/// Provider for the permissions available in the current active organization.
final activePermissionsProvider = Provider<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  final activeOrgId = ref.watch(activeOrganizationProvider);

  if (authState.identity == null || activeOrgId == null) {
    return const [];
  }

  final membership = authState.identity!.memberships.firstWhere(
    (m) => m.organizationId == activeOrgId,
    orElse: () => const OrganizationMembership(
      id: '',
      organizationId: '',
      organization: OrganizationInfo(id: '', name: '', slug: ''),
      roles: [],
      permissions: [],
    ),
  );

  return membership.permissions;
});

/// Extension to easily check permissions from WidgetRef.
extension AuthPermissionsX on WidgetRef {
  bool can(String permission) {
    return watch(activePermissionsProvider).contains(permission);
  }

  bool hasRole(UserRole role) {
    return watch(authStateProvider).identity?.role == role;
  }
}
