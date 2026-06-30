import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Auth plus Google sign in.
///
/// Google is initialized lazily inside [signInWithGoogle] and guarded, so the
/// app still starts and email/password still works even before the Google
/// provider is enabled in the Firebase console.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleReady = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Guest mode: signs in anonymously. The user gets a uid (so their data is
  /// still scoped and cloud stored), but the account has no recoverable
  /// credential. They can later link email/Google to keep the data.
  Future<UserCredential> signInAsGuest() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize();
      _googleReady = true;
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-no-id-token',
        message: 'Google did not return an identity token.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google may not be initialized; ignore.
    }
    await _auth.signOut();
  }
}
