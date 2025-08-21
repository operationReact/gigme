import 'package:flutter/foundation.dart';

/// Simple in-memory auth/profile state (placeholder for real backend auth)
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserType? _userType;
  bool _freelancerProfileCreated = false;
  bool _clientProfileCreated = false;
  String? _userName; // display name

  bool get isLoggedIn => _userType != null;
  UserType? get userType => _userType;
  String? get userName => _userName;

  bool get freelancerProfileCreated => _freelancerProfileCreated;
  bool get clientProfileCreated => _clientProfileCreated;

  void login(UserType type, {String? name}) {
    _userType = type;
    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
    }
    notifyListeners();
  }

  void setFreelancerProfile({required String displayName}) {
    _freelancerProfileCreated = true;
    _userName = displayName.trim();
    _userType = UserType.freelancer;
    notifyListeners();
  }

  void setClientProfile({required String displayName}) {
    _clientProfileCreated = true;
    _userName = displayName.trim();
    _userType = UserType.client;
    notifyListeners();
  }

  void logout() {
    _userType = null;
    _userName = null;
    notifyListeners();
  }
}

enum UserType { freelancer, client }

