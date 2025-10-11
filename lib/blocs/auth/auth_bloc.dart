import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthState.initial) {
    on<AuthInitialize>(_onInitialize);
    on<AuthSignIn>(_onSignIn);
    on<AuthSignOut>(_onSignOut);
  }

  Future<void> _onInitialize(
    AuthInitialize event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    await _authRepository.initialize();

    if (_authRepository.isSignedIn) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          userEmail: _authRepository.getUserEmail(),
          userName: _authRepository.getUserDisplayName(),
          userPhotoUrl: _authRepository.getUserPhotoUrl(),
        ),
      );
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignIn(AuthSignIn event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final success = await _authRepository.signIn();

    if (success) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          userEmail: _authRepository.getUserEmail(),
          userName: _authRepository.getUserDisplayName(),
          userPhotoUrl: _authRepository.getUserPhotoUrl(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Failed to sign in',
        ),
      );
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _authRepository.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }
}
