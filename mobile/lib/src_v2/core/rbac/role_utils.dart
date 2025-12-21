class RoleUtils {
  static List<String> rolesFromUser(dynamic user) {
    if (user is Map<String, dynamic>) {
      final raw = user['roles'];
      if (raw is List) {
        return raw.map((e) => e.toString().toUpperCase().trim()).toList();
      }
    }
    return const [];
  }

  static bool hasRole(dynamic user, String role) {
    final roles = rolesFromUser(user);
    return roles.contains(role.toUpperCase().trim());
  }
}
