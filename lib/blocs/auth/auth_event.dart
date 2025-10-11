import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitialize extends AuthEvent {
  const AuthInitialize();
}

class AuthSignIn extends AuthEvent {
  const AuthSignIn();
}

class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}
