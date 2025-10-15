import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../services/google_drive_service.dart';

class AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      // Full Drive access to allow reading existing user files for selected folders
      'https://www.googleapis.com/auth/drive',
    ],
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleDriveService _driveService;

  GoogleSignInAccount? _currentUser;

  AuthRepository(this._driveService);

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isDriveApiInitialized => _driveService.isInitialized;

  Future<void> _initializeDriveApi(GoogleSignInAccount account) async {
    developer.log(
      'Initializing Drive API for ${account.email}',
      name: 'AuthRepository',
    );

    final authHeaders = await account.authHeaders;
    if (authHeaders['Authorization'] == null) {
      throw Exception('No authorization header available');
    }

    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        authHeaders['Authorization']!.replaceFirst('Bearer ', ''),
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      ['https://www.googleapis.com/auth/drive'],
    );

    final authClient = authenticatedClient(http.Client(), credentials);
    await _driveService.initialize(authClient);

    developer.log(
      'Drive API initialized successfully for ${account.email}',
      name: 'AuthRepository',
    );
  }

  Future<void> initialize() async {
    // Just update the current user reference
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
    });

    try {
      // Try to sign in silently
      final account = await _googleSignIn.signInSilently();

      // Initialize Drive API if silent sign-in succeeded
      if (account != null) {
        _currentUser = account;
        await _initializeDriveApi(account);
      }
    } catch (e) {
      developer.log('Silent sign in error: $e', name: 'AuthRepository');
      _currentUser = null;
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
    if (authHeaders['Authorization'] == null) return null;

    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        authHeaders['Authorization']!.replaceFirst('Bearer ', ''),
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      ['https://www.googleapis.com/auth/drive'],
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
