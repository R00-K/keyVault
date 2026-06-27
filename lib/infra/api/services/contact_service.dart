import 'dart:convert';

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

  Map<String, dynamic> toMap() => {
    'name': name,
    'verification': verification,
    'messagePreview': messagePreview,
    'time': time,
    'unreadCount': unreadCount,
    'sessionId': sessionId,
    'to': to,
    'peerPublicKey': peerPublicKey,
  };

  factory TrustedContact.fromMap(Map<String, dynamic> map) => TrustedContact(
    name: map['name'] as String? ?? '',
    verification: map['verification'] as String? ?? '',
    messagePreview: map['messagePreview'] as String? ?? '',
    time: map['time'] as String? ?? '',
    unreadCount: map['unreadCount'] as int? ?? 0,
    sessionId: map['sessionId'] as String? ?? '',
    to: map['to'] as String? ?? '',
    peerPublicKey: map['peerPublicKey'] as String? ?? '',
  );
}

class ContactService {
  ContactService._();

  static final List<TrustedContact> _contacts = [];

  static List<TrustedContact> get contacts => List.unmodifiable(_contacts);

  static int get count => _contacts.length;

  /// Load contacts from persistent storage (SecureKeyStorage).
  static Future<void> loadContacts() async {
    final raw = await SecureKeyStorage.read(key: 'trusted_contacts');
    if (raw == null || raw.isEmpty) return;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _contacts.clear();
      for (final item in list) {
        _contacts.add(TrustedContact.fromMap(item as Map<String, dynamic>));
      }
    } catch (_) {
      _contacts.clear();
    }
  }

  /// Persist a contact to both in-memory list and SecureKeyStorage.
  static Future<void> addContact(TrustedContact contact) async {
    _contacts.add(contact);
    await _saveToStorage();
    await SecureKeyStorage.saveHasTrustedContact();
  }

  static Future<void> _saveToStorage() async {
    final list = _contacts.map((c) => c.toMap()).toList();
    await SecureKeyStorage.write(key: 'trusted_contacts', value: jsonEncode(list));
  }

  /// Remove a contact by sessionId.
  static Future<void> removeContact(String sessionId) async {
    _contacts.removeWhere((c) => c.sessionId == sessionId);
    await _saveToStorage();
  }
}
