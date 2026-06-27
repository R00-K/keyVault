import '../../../crypto/secure_key_storage.dart';

class TrustedContact {
  final String name;
  final String verification;
  final String messagePreview;
  final String time;
  final int unreadCount;
  final String sessionId;
  final String to;
  final String peerPublicKey;

  const TrustedContact({
    required this.name,
    required this.verification,
    required this.messagePreview,
    this.time = '',
    this.unreadCount = 0,
    this.sessionId = '',
    this.to = '',
    this.peerPublicKey = '',
  });
}

class ContactService {
  ContactService._();

  static final List<TrustedContact> _contacts = [];

  static List<TrustedContact> get contacts => List.unmodifiable(_contacts);

  static int get count => _contacts.length;

  static Future<void> loadContacts() async {
    _contacts.clear();

    final countStr = await SecureKeyStorage.read(key: 'contact_count');
    if (countStr == null || countStr.isEmpty) return;

    final count = int.tryParse(countStr);
    if (count == null || count <= 0) return;

    for (var i = 0; i < count; i++) {
      final prefix = 'contact_${i}_';
      final name = await SecureKeyStorage.read(key: '${prefix}name');
      if (name == null) continue;

      final contact = TrustedContact(
        name: name,
        verification: await SecureKeyStorage.read(key: '${prefix}verification') ?? '',
        messagePreview: await SecureKeyStorage.read(key: '${prefix}messagePreview') ?? '',
        time: await SecureKeyStorage.read(key: '${prefix}time') ?? '',
        unreadCount: int.tryParse(
          await SecureKeyStorage.read(key: '${prefix}unreadCount') ?? '',
        ) ?? 0,
        sessionId: await SecureKeyStorage.read(key: '${prefix}sessionId') ?? '',
        to: await SecureKeyStorage.read(key: '${prefix}to') ?? '',
        peerPublicKey: await SecureKeyStorage.read(key: '${prefix}peerPublicKey') ?? '',
      );
      _contacts.add(contact);
    }
  }

  static Future<void> addContact(TrustedContact contact) async {
    _contacts.add(contact);
    await _saveToStorage();
    await SecureKeyStorage.saveHasTrustedContact();
  }

  static Future<void> _saveToStorage() async {
    final count = _contacts.length;
    await SecureKeyStorage.write(key: 'contact_count', value: count.toString());

    for (var i = 0; i < count; i++) {
      final c = _contacts[i];
      final prefix = 'contact_${i}_';
      await SecureKeyStorage.write(key: '${prefix}name', value: c.name);
      await SecureKeyStorage.write(key: '${prefix}verification', value: c.verification);
      await SecureKeyStorage.write(key: '${prefix}messagePreview', value: c.messagePreview);
      await SecureKeyStorage.write(key: '${prefix}time', value: c.time);
      await SecureKeyStorage.write(key: '${prefix}unreadCount', value: c.unreadCount.toString());
      await SecureKeyStorage.write(key: '${prefix}sessionId', value: c.sessionId);
      await SecureKeyStorage.write(key: '${prefix}to', value: c.to);
      await SecureKeyStorage.write(key: '${prefix}peerPublicKey', value: c.peerPublicKey);
    }
  }

  static Future<void> removeContact(String sessionId) async {
    _contacts.removeWhere((c) => c.sessionId == sessionId);
    await _saveToStorage();
  }
}
