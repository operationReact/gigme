import 'package:flutter/foundation.dart';
import '../api/auth_api.dart';

class SessionService extends ChangeNotifier {
  SessionService._();
  static final SessionService instance = SessionService._();

  AuthUser? _user;
  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isFreelancer => _user?.role == 'FREELANCER';
  bool get isClient => _user?.role == 'CLIENT';

  void setUser(AuthUser u) { _user = u; notifyListeners(); }
  void updateProfiles({bool? hasFreelancer, bool? hasClient}) {
    if (_user == null) return;
    _user = AuthUser(
      id: _user!.id,
      email: _user!.email,
      role: _user!.role,
      hasFreelancerProfile: hasFreelancer ?? _user!.hasFreelancerProfile,
      hasClientProfile: hasClient ?? _user!.hasClientProfile,
    );
    notifyListeners();
  }
  void logout() { _user = null; notifyListeners(); }
}

