import 'package:flutter/foundation.dart';
import 'package:mobile/src_v2/core/auth/patient_token_store.dart';

class PatientSessionStore extends ChangeNotifier {
  bool _ready = false;
  bool _authed = false;

  bool get isReady => _ready;
  bool get isAuthenticated => _authed;

  Future<void> bootstrap() async {
    final t = await PatientTokenStore.getAccessToken();
    _authed = (t != null && t.trim().isNotEmpty);
    _ready = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    final t = await PatientTokenStore.getAccessToken();
    final next = (t != null && t.trim().isNotEmpty);
    if (next != _authed) {
      _authed = next;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await PatientTokenStore.clear();
    _authed = false;
    notifyListeners();
  }
}
