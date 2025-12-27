class RoleUtils {
  static bool hasRole(Map<String, dynamic>? user, String role) {
    if (user == null) return false;

    final target = role.toUpperCase().trim();

    final rolesRaw = user['roles'];
    if (rolesRaw is List) {
      for (final r in rolesRaw) {
        if (r == null) continue;

        if (r is String) {
          if (r.toUpperCase().trim() == target) return true;
        } else if (r is Map) {
          final code = (r['code'] ?? r['name'] ?? r['role'] ?? r['value'] ?? '')
              .toString();
          if (code.toUpperCase().trim() == target) return true;
        } else {
          final s = r.toString();
          if (s.toUpperCase().trim() == target) return true;
        }
      }
    }

    // fallback: single role string
    final single = (user['role'] ?? user['userRole'] ?? user['type'] ?? '')
        .toString();
    if (single.isNotEmpty && single.toUpperCase().trim() == target) return true;

    return false;
  }
}
