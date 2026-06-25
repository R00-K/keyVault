class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const completeProfile = '/complete-profile';
  static const home = '/home';
  static const chat = '/chat/:contactName';

  static String chatFor(String contactName) {
    return '/chat/${Uri.encodeComponent(contactName)}';
  }
}
