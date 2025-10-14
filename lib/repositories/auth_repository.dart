import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../services/google_drive_service.dart';

class AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.metadata.readonly',
    ],
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleDriveService _driveService;

  GoogleSignInAccount? _currentUser;

  AuthRepository(this._driveService);

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> _initializeDriveApi(GoogleSignInAccount account) async {
    try {
      final authHeaders = await account.authHeaders;
      final credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          authHeaders['Authorization']!.replaceFirst('Bearer ', ''),
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        [],
      );

      final authClient = authenticatedClient(http.Client(), credentials);
      await _driveService.initialize(authClient);
    } catch (e) {
      developer.log('Error initializing Drive API: $e', name: 'AuthRepository');
    }
  }

  Future<void> initialize() async {
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _currentUser = account;

      // Initialize Drive API when user changes
      if (account != null) {
        await _initializeDriveApi(account);
      }
    });

    // Try to sign in silently
    final account = await _googleSignIn.signInSilently();

    // Initialize Drive API if silent sign-in succeeded
    if (account != null) {
      await _initializeDriveApi(account);
    }
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      _currentUser = account;

      // Initialize Drive service
      await _initializeDriveApi(account);

      // Save auth state
      await _secureStorage.write(key: 'auth_email', value: account.email);

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
    final account = await _googleSignIn.signInSilently();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        authHeaders['Authorization']!.replaceFirst('Bearer ', ''),
        DateTime.now().add(const Duration(hours: 1)),
      ),
      null,
      [],
    );

    return authenticatedClient(http.Client(), credentials);
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
