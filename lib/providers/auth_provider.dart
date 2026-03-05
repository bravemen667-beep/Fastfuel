// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — GFAuthProvider
//
//  PRODUCTION AUTH RULES:
//  • Google Sign-In   → real GoogleSignIn().signIn() + Firebase credential
//  • Phone/OTP        → real FirebaseAuth.verifyPhoneNumber + PhoneAuthCredential
//  • NO guest bypass  → continueAsGuest is disabled; calling it is a no-op
//  • Auth state       → driven by FirebaseAuth.instance.authStateChanges()
//  • Sensitive data   → stored in flutter_secure_storage, NOT SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Auth Status ───────────────────────────────────────────────────────────────
enum AuthStatus { unknown, unauthenticated, authenticated }

// ── Phone Verification State ──────────────────────────────────────────────────
enum PhoneVerificationState { idle, sending, codeSent, verifying, error }

class GFAuthProvider extends ChangeNotifier {
  // ── Firebase & storage instances ────────────────────────────────────────────
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Internal state ───────────────────────────────────────────────────────────
  AuthStatus _status    = AuthStatus.unknown;
  User?      _firebaseUser;
  bool       _isLoading = false;
  String?    _errorMessage;

  // Phone auth flow state
  PhoneVerificationState _phoneState = PhoneVerificationState.idle;
  String? _verificationId;
  int?    _forceResendingToken;
  int     _otpAttempts = 0;
  static const int maxOtpAttempts = 3;

  // ── Getters ──────────────────────────────────────────────────────────────────
  AuthStatus get status         => _status;
  bool       get isAuthenticated => _status == AuthStatus.authenticated;
  bool       get isLoading      => _isLoading;
  bool       get isGuest        => false; // Guest mode permanently disabled
  String?    get errorMessage   => _errorMessage;
  PhoneVerificationState get phoneState => _phoneState;
  bool       get canResendOtp   => _phoneState != PhoneVerificationState.sending;
  int        get otpAttempts    => _otpAttempts;
  bool       get otpBlocked     => _otpAttempts >= maxOtpAttempts;

  // Firebase user details
  String get uid       => _firebaseUser?.uid ?? '';
  String get userName  => _firebaseUser?.displayName ?? _firebaseUser?.phoneNumber ?? 'User';
  String get userPhone => _firebaseUser?.phoneNumber ?? '';
  String get userEmail => _firebaseUser?.email ?? '';
  bool   get hasPhoto  => _firebaseUser?.photoURL != null;
  String get photoUrl  => _firebaseUser?.photoURL ?? '';
  String get authMethod {
    if (_firebaseUser == null) return '';
    final providers = _firebaseUser!.providerData.map((p) => p.providerId).toList();
    if (providers.contains('google.com')) return 'google';
    if (providers.contains('phone'))      return 'phone';
    return 'unknown';
  }

  /// Stable UID for Firestore paths
  String get firestoreUid => uid.isNotEmpty ? uid : 'anonymous';

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ── Initialise — listen to FirebaseAuth stream ──────────────────────────────
  Future<void> init() async {
    _firebaseAuth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    });
    // Trigger one-time read immediately
    final current = _firebaseAuth.currentUser;
    _firebaseUser = current;
    _status = current != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── GOOGLE SIGN-IN ────────────────────────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      // Step 1: show Google account picker
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        // User cancelled
        _setLoading(false);
        return false;
      }

      // Step 2: get auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;

      if (googleAuth.idToken == null) {
        _setError('Google Sign-In failed: no ID token received.');
        return false;
      }

      // Step 3: create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken:     googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Step 4: sign in to Firebase
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      _firebaseUser = userCredential.user;
      await _saveAuthMethod('google');
      _setLoading(false);
      return _firebaseUser != null;

    } on Exception catch (e) {
      final msg = _parseGoogleError(e);
      _setError(msg);
      return false;
    }
  }

  String _parseGoogleError(Object e) {
    final s = e.toString();
    if (s.contains('network_error') || s.contains('network error')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (s.contains('sign_in_failed') || s.contains('sign_in_canceled')) {
      return 'Google Sign-In failed. Please try again.';
    }
    if (s.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email using a different sign-in method.';
    }
    if (s.contains('invalid-credential')) {
      return 'Invalid credentials. Please try again.';
    }
    return 'Sign-In failed. Please try again.';
  }

  // ── PHONE / OTP AUTH ──────────────────────────────────────────────────────────

  /// Step 1 — send OTP via Firebase Phone Auth
  Future<bool> sendOtp(String phone) async {
    _setLoading(true);
    _clearError();
    _otpAttempts = 0;
    setState(() => _phoneState = PhoneVerificationState.sending);

    // Normalise phone number to E.164 format
    final e164 = phone.startsWith('+') ? phone : '+91$phone';

    final completer = _AsyncCompleter<bool>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: _forceResendingToken,
      timeout: const Duration(seconds: 60),

      // Auto-retrieval (SMS auto-read on Android)
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-fills OTP on supported devices
        setState(() => _phoneState = PhoneVerificationState.verifying);
        try {
          final uc = await _firebaseAuth.signInWithCredential(credential);
          _firebaseUser = uc.user;
          await _saveAuthMethod('phone');
          setState(() => _phoneState = PhoneVerificationState.idle);
          if (!completer.isCompleted) completer.complete(true);
        } catch (_) {
          setState(() => _phoneState = PhoneVerificationState.error);
          if (!completer.isCompleted) completer.complete(false);
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        final msg = _parsePhoneSendError(e);
        _setError(msg);
        setState(() => _phoneState = PhoneVerificationState.error);
        _setLoading(false);
        if (!completer.isCompleted) completer.complete(false);
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId    = verificationId;
        _forceResendingToken = resendToken;
        setState(() => _phoneState = PhoneVerificationState.codeSent);
        _setLoading(false);
        if (!completer.isCompleted) completer.complete(true);
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        // Don't change state — user may still enter manually
      },
    );

    return completer.future;
  }

  /// Step 2 — verify OTP entered by user.
  /// Returns true on success, false on wrong OTP.
  /// Throws [OtpBlockedException] after maxOtpAttempts.
  Future<bool> loginWithPhone({required String phone, required String otp}) async {
    if (otpBlocked) {
      throw OtpBlockedException('Maximum attempts reached. Request a new OTP.');
    }
    if (otp.length != 6) {
      _setError('Enter all 6 digits.');
      return false;
    }
    if (_verificationId == null) {
      _setError('Session expired. Please request a new OTP.');
      return false;
    }

    _setLoading(true);
    _clearError();
    setState(() => _phoneState = PhoneVerificationState.verifying);

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final UserCredential uc =
          await _firebaseAuth.signInWithCredential(credential);

      _firebaseUser = uc.user;
      await _saveAuthMethod('phone');
      _otpAttempts = 0;
      setState(() => _phoneState = PhoneVerificationState.idle);
      _setLoading(false);
      return _firebaseUser != null;

    } on FirebaseAuthException catch (e) {
      _otpAttempts++;
      final remaining = maxOtpAttempts - _otpAttempts;
      String msg;
      if (e.code == 'invalid-verification-code' || e.code == 'invalid-credential') {
        msg = remaining > 0
            ? 'Wrong OTP. $remaining attempt${remaining == 1 ? "" : "s"} remaining.'
            : 'Too many wrong attempts. Request a new OTP.';
      } else if (e.code == 'session-expired') {
        msg = 'OTP session expired. Please request a new OTP.';
      } else {
        msg = 'Verification failed. Please try again.';
      }
      _setError(msg);
      setState(() => _phoneState = PhoneVerificationState.codeSent);
      _setLoading(false);
      return false;
    }
  }

  String _parsePhoneSendError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try Google Sign-In instead.';
      case 'app-not-authorized':
        return 'App not authorized. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Could not send OTP (${e.code}). Please try again.';
    }
  }

  // ── GUEST MODE — PERMANENTLY DISABLED ─────────────────────────────────────
  /// Guest bypass is permanently disabled in this production build.
  /// Calling this is a no-op and will NOT navigate to home.
  Future<void> continueAsGuest() async {
    debugPrint('[GFAuthProvider] continueAsGuest() called but guest mode is disabled.');
  }

  // ── SIGN OUT ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Sign out from Google if it was used
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      await _secureStorage.deleteAll();
      _verificationId      = null;
      _forceResendingToken = null;
      _otpAttempts         = 0;
      _phoneState          = PhoneVerificationState.idle;
    } finally {
      _setLoading(false);
    }
    // _firebaseUser + _status updated automatically by authStateChanges listener
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _isLoading    = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ignore: use_setters_to_change_properties
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<void> _saveAuthMethod(String method) async {
    await _secureStorage.write(key: 'auth_method', value: method);
  }
}

// ── Custom Exceptions ────────────────────────────────────────────────────────
class OtpBlockedException implements Exception {
  final String message;
  const OtpBlockedException(this.message);
  @override
  String toString() => message;
}

// ── Simple async completer helper ────────────────────────────────────────────
class _AsyncCompleter<T> {
  bool _completed = false;
  late T _result;
  final _callbacks = <void Function(T)>[];

  bool get isCompleted => _completed;

  void complete(T value) {
    if (_completed) return;
    _completed = true;
    _result    = value;
    for (final cb in _callbacks) { cb(value); }
  }

  Future<T> get future async {
    if (_completed) return _result;
    return Future.any([
      Future.delayed(const Duration(seconds: 65), () => false as T),
      Future(() async {
        while (!_completed) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return _result;
      }),
    ]);
  }
}
