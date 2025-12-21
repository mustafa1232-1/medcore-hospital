enum ShellPage { home, staff, orders, tasks, account }

extension ShellPageX on ShellPage {
  String get key {
    switch (this) {
      case ShellPage.home:
        return 'home';
      case ShellPage.staff:
        return 'staff';
      case ShellPage.orders:
        return 'orders';
      case ShellPage.tasks:
        return 'tasks';
      case ShellPage.account:
        return 'account';
    }
  }
}
