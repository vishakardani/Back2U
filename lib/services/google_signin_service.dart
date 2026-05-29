import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  // Initialize Google Sign-In
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // CHARUSAT domain constant
  static const String CHARUSAT_DOMAIN = '@charusat.edu.in';

  // Check if user is already signed in
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Get current signed-in account
  static Future<GoogleSignInAccount?> getCurrentAccount() async {
    return _googleSignIn.currentUser;
  }

  // Sign in with Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      debugPrint('🔐 Attempting Google Sign-In...');
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      debugPrint('❌ Google Sign-In Error: $error');
      rethrow;
    }
  }

  // Sign out from Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ Signed out from Google');
    } catch (error) {
      debugPrint('❌ Google Sign-Out Error: $error');
      rethrow;
    }
  }

  // Disconnect completely
  static Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('✅ Disconnected from Google');
    } catch (error) {
      debugPrint('❌ Google Disconnect Error: $error');
      rethrow;
    }
  }

  // Get ID Token (for backend verification)
  static Future<String?> getIdToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint('⚠️ No Google account signed in');
        return null;
      }

      final auth = await account.authentication;
      return auth.idToken;
    } catch (error) {
      debugPrint('❌ Error getting ID Token: $error');
      return null;
    }
  }

  // Get Access Token
  static Future<String?> getAccessToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint('⚠️ No Google account signed in');
        return null;
      }

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (error) {
      debugPrint('❌ Error getting Access Token: $error');
      return null;
    }
  }

  // Validate CHARUSAT email
  static bool isValidCharusatEmail(String email) {
    return email.toLowerCase().endsWith(CHARUSAT_DOMAIN);
  }

  // Get user info from Google account
  static Map<String, String> getUserInfo(GoogleSignInAccount account) {
    return {
      'email': account.email,
      'displayName': account.displayName ?? '',
      'photoUrl': account.photoUrl ?? '',
      'id': account.id,
    };
  }

  // Parse first and last name from displayName
  static Map<String, String> parseFullName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return {'firstName': '', 'lastName': ''};
    }

    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) {
      return {'firstName': '', 'lastName': ''};
    }

    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return {'firstName': firstName, 'lastName': lastName};
  }

  // Complete Google Sign-In flow with validation
  static Future<GoogleSignInResult> signInWithValidation() async {
    try {
      debugPrint('🔐 Starting Google Sign-In flow...');

      // Step 1: Sign in with Google
      final account = await signIn();
      if (account == null) {
        return GoogleSignInResult(
          success: false,
          error: 'Sign-in was cancelled',
        );
      }

      debugPrint('✅ Signed in as: ${account.email}');

      // Step 2: Validate CHARUSAT email domain
      if (!isValidCharusatEmail(account.email)) {
        await signOut();
        return GoogleSignInResult(
          success: false,
          error: 'Please sign in with your CHARUSAT email (@charusat.edu.in)',
        );
      }

      debugPrint('✅ Email domain validated');

      // Step 3: Get ID Token
      final idToken = await getIdToken();
      if (idToken == null) {
        return GoogleSignInResult(
          success: false,
          error: 'Failed to get authentication token',
        );
      }

      debugPrint('✅ ID Token obtained');

      // Step 4: Get user info
      final userInfo = getUserInfo(account);
      final names = parseFullName(account.displayName);

      return GoogleSignInResult(
        success: true,
        email: account.email,
        firstName: names['firstName'] ?? '',
        lastName: names['lastName'] ?? '',
        photoUrl: account.photoUrl,
        idToken: idToken,
        accessToken: await getAccessToken(),
        googleUserId: account.id,
      );
    } catch (error) {
      debugPrint('❌ Google Sign-In Error: $error');
      return GoogleSignInResult(success: false, error: error.toString());
    }
  }
}

// Result class for Google Sign-In
class GoogleSignInResult {
  final bool success;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? idToken;
  final String? accessToken;
  final String? googleUserId;
  final String? error;

  GoogleSignInResult({
    required this.success,
    this.email,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.idToken,
    this.accessToken,
    this.googleUserId,
    this.error,
  });

  @override
  String toString() =>
      '''
GoogleSignInResult(
  success: $success,
  email: $email,
  firstName: $firstName,
  lastName: $lastName,
  error: $error
)
''';
}
