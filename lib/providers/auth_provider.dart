import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────
//  Auth Status
// ─────────────────────────────────────────────────────────
enum AuthStatus { unknown, unauthenticated, authenticated, guest }

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn   = 'gf_logged_in';
  static const _keyAuthMethod = 'gf_auth_method';
  static const _keyUserName   = 'gf_user_name';
  static const _keyUserPhone  = 'gf_user_phone';
  static const _keyIsGuest    = 'gf_is_guest';
  static const _keyUid        = 'gf_uid';

  AuthStatus _status = AuthStatus.unknown;
  String _userName   = '';
  String _userPhone  = '';
  String _authMethod = '';
  bool _isGuest      = false;
  bool _isLoading    = false;
  String _uid        = '';

  AuthStatus get status     => _status;
  String get userName       => _userName;
  String get userPhone      => _userPhone;
  String get authMethod     => _authMethod;
  bool get isGuest          => _isGuest;
  bool get isLoading        => _isLoading;
  bool get isAuthenticated  => _status == AuthStatus.authenticated || _status == AuthStatus.guest;

  /// Stable user identifier used for Firestore document paths.
  /// For phone auth, derived from the phone number; for guests a fixed key.
  String get uid => _uid;

  // ── Init ─────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    final isGuest  = prefs.getBool(_keyIsGuest)  ?? false;

    if (loggedIn) {
      _userName   = prefs.getString(_keyUserName)   ?? 'User';
      _userPhone  = prefs.getString(_keyUserPhone)  ?? '';
      _authMethod = prefs.getString(_keyAuthMethod) ?? 'phone';
      _isGuest    = isGuest;
      _uid        = prefs.getString(_keyUid)        ?? _uidFromPhone(_userPhone);
      _status = isGuest ? AuthStatus.guest : AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Phone / OTP Login ────────────────────────────────
  Future<bool> loginWithPhone({
    required String phone,
    required String otp,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Simulate OTP verification (replace with real API in production)
    await Future.delayed(const Duration(milliseconds: 1200));

    // Accept any 4-6 digit OTP for demo
    if (otp.length >= 4 && otp.length <= 6) {
      await _persistLogin(
        name: _nameFromPhone(phone),
        phone: phone,
        method: 'phone',
        isGuest: false,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Simulate sending OTP
  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false;
    notifyListeners();
    return true; // Always succeeds in demo
  }

  // ── Google Sign-In ───────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1500));
    await _persistLogin(
      name: 'Alex Kumar',
      phone: '',
      method: 'google',
      isGuest: false,
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Guest ─────────────────────────────────────────────
  Future<void> continueAsGuest() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    await _persistLogin(
      name: 'Guest',
      phone: '',
      method: 'guest',
      isGuest: true,
    );
    _isLoading = false;
    notifyListeners();
  }

  // ── Logout ───────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyAuthMethod);
    await prefs.remove(_keyIsGuest);
    await prefs.remove(_keyUid);

    _status     = AuthStatus.unauthenticated;
    _userName   = '';
    _userPhone  = '';
    _authMethod = '';
    _isGuest    = false;
    _uid        = '';
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────
  Future<void> _persistLogin({
    required String name,
    required String phone,
    required String method,
    required bool isGuest,
  }) async {
    final uid = isGuest ? 'guest_user' : _uidFromPhone(phone);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn,   true);
    await prefs.setString(_keyUserName,   name);
    await prefs.setString(_keyUserPhone,  phone);
    await prefs.setString(_keyAuthMethod, method);
    await prefs.setBool(_keyIsGuest,    isGuest);
    await prefs.setString(_keyUid,      uid);

    _userName   = name;
    _userPhone  = phone;
    _authMethod = method;
    _isGuest    = isGuest;
    _uid        = uid;
    _status = isGuest ? AuthStatus.guest : AuthStatus.authenticated;
  }

  String _uidFromPhone(String phone) {
    // Sanitise to alphanumeric for use as Firestore doc ID
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.isEmpty ? 'user_default' : 'user_$clean';
  }

  String _nameFromPhone(String phone) {
    if (phone.isEmpty) return 'User';
    final last4 = phone.length >= 4 ? phone.substring(phone.length - 4) : phone;
    return 'User $last4';
  }

  // Greeting based on time
  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
