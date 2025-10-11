import 'package:equatable/equatable.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? userEmail;
  final String? userName;
  final String? userPhotoUrl;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.userEmail,
    this.userName,
    this.userPhotoUrl,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    status,
    userEmail,
    userName,
    userPhotoUrl,
    errorMessage,
  ];

  AuthState copyWith({
    AuthStatus? status,
    String? userEmail,
    String? userName,
    String? userPhotoUrl,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static const initial = AuthState(status: AuthStatus.initial);
}
