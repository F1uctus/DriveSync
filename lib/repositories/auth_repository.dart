import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../services/google_drive_service.dart';

class AuthRepository {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleDriveService _driveService;

  GoogleSignInAccount? _currentUser;

  AuthRepository(this._driveService);

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> initialize() async {
    // Initialize GoogleSignIn
    await _googleSignIn.initialize();

    // Listen to authentication events
    _googleSignIn.authenticationEvents.listen(
      (event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            _currentUser = event.user;
            break;
          case GoogleSignInAuthenticationEventSignOut():
            _currentUser = null;
            break;
        }
      },
      onError: (error) {
        developer.log('Authentication error: $error', name: 'AuthRepository');
      },
    );

    // Try lightweight authentication
    try {
      await _googleSignIn.attemptLightweightAuthentication();
    } catch (e) {
      developer.log('Lightweight authentication failed: $e',
          name: 'AuthRepository');
    }
  }

  Future<bool> signIn() async {
    try {
      // Use authenticate instead of signIn
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate();
      } else {
        // Fallback for platforms that don't support authenticate
        developer.log('Platform does not support authenticate()',
            name: 'AuthRepository');
        return false;
      }

      // Wait for authentication event to update _currentUser
      await Future.delayed(const Duration(milliseconds: 500));

      if (_currentUser == null) return false;

      // Request authorization for scopes
      final authorization = await _currentUser!.authorizationClient
          .authorizeScopes(_scopes);

      // Initialize Drive service with auth client
      final credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          authorization.accessToken,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        _scopes,
      );

      final authClient = authenticatedClient(http.Client(), credentials);
      await _driveService.initialize(authClient);

      // Save auth state
      await _secureStorage.write(key: 'auth_email', value: _currentUser!.email);

      return true;
    } catch (e) {
      developer.log('Sign in error: $e', name: 'AuthRepository');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    await _secureStorage.deleteAll();
  }

  Future<AuthClient?> getAuthClient() async {
    if (_currentUser == null) return null;

    try {
      // Check if we already have authorization for the required scopes
      final authorization = await _currentUser!.authorizationClient
          .authorizationForScopes(_scopes);

      if (authorization == null) {
        // Need to request authorization
        final newAuthorization = await _currentUser!.authorizationClient
            .authorizeScopes(_scopes);

        final credentials = AccessCredentials(
          AccessToken(
            'Bearer',
            newAuthorization.accessToken,
            DateTime.now().add(const Duration(hours: 1)),
          ),
          null,
          _scopes,
        );

        return authenticatedClient(http.Client(), credentials);
      }

      final credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          authorization.accessToken,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        _scopes,
      );

      return authenticatedClient(http.Client(), credentials);
    } catch (e) {
      developer.log('Get auth client error: $e', name: 'AuthRepository');
      return null;
    }
  }

  String? getUserEmail() {
    return _currentUser?.email;
  }

  String? getUserDisplayName() {
    return _currentUser?.displayName;
  }

  String? getUserPhotoUrl() {
    return _currentUser?.photoUrl;
  }
}
