class RouteNames {
  RouteNames._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const completeProfile = '/complete-profile';
  static const home = '/home';
  static const chat = '/chat/:contactName';
  static const establishTrust = '/trust/establish';
  static const receiveTrust = '/trust/receive';
  static const establishTrustQr = '/trust/establish/qr';
  static const receiveTrustQr = '/trust/receive/qr';
  static const establishTrustNfc = '/trust/establish/nfc';
  static const receiveTrustNfc = '/trust/receive/nfc';
  static const establishTrustManual = '/trust/establish/manual';
  static const receiveTrustManual = '/trust/receive/manual';

  static String chatFor(String contactName) {
    return '/chat/${Uri.encodeComponent(contactName)}';
  }
}
