enum ShellPage { home, staff, account }

extension ShellPageX on ShellPage {
  String get key {
    switch (this) {
      case ShellPage.home:
        return 'home';
      case ShellPage.staff:
        return 'staff';
      case ShellPage.account:
        return 'account';
    }
  }
}
