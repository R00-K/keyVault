import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

// ─── incremental change event ───────────────────────────────────────────────
sealed class LocalChangeEvent {
  final String sessionId;
  const LocalChangeEvent(this.sessionId);
}

class MessageAdded extends LocalChangeEvent {
  final ChatMessageModel message;
  const MessageAdded(super.sessionId, this.message);
}

class MessageUpdated extends LocalChangeEvent {
  final ChatMessageModel message;
  const MessageUpdated(super.sessionId, this.message);
}

class SessionCleared extends LocalChangeEvent {
  const SessionCleared(super.sessionId);
}

// ─── LocalChatStorage ────────────────────────────────────────────────────────
class LocalChatStorage {
  Database? _db;

  final _changes = StreamController<LocalChangeEvent>.broadcast();

  Future<void> initialize() async {
    if (_db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/keyvault_chat.db';

    try {
      _db = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE messages (
              messageId TEXT PRIMARY KEY,
              fromUser TEXT NOT NULL,
              toUser TEXT NOT NULL,
              sessionId TEXT NOT NULL,
              cipherText TEXT NOT NULL,
              nonce TEXT NOT NULL,
              mac TEXT NOT NULL,
              plainText TEXT,
              timestamp INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'sent'
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_messages_session_time
            ON messages(sessionId, timestamp)
          ''');

          await db.execute('''
            CREATE TABLE sessions (
              sessionId TEXT PRIMARY KEY,
              contactId TEXT NOT NULL,
              keyVaultId TEXT NOT NULL,
              displayName TEXT NOT NULL,
              peerPublicKey TEXT NOT NULL,
              isTrusted INTEGER NOT NULL DEFAULT 0,
              lastMessage TEXT,
              lastMessageTime INTEGER,
              unreadCount INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute(
                  'ALTER TABLE messages ADD COLUMN plainText TEXT');
            } catch (_) {}
          }
        },
      );
    } catch (_) {
      // If open fails (corrupted DB, schema mismatch, etc.),
      // delete and recreate from scratch
      try {
        await deleteDatabase(dbPath);
      } catch (_) {}
      _db = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE messages (
              messageId TEXT PRIMARY KEY,
              fromUser TEXT NOT NULL,
              toUser TEXT NOT NULL,
              sessionId TEXT NOT NULL,
              cipherText TEXT NOT NULL,
              nonce TEXT NOT NULL,
              mac TEXT NOT NULL,
              plainText TEXT,
              timestamp INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'sent'
            )
          ''');
          await db.execute('''
            CREATE INDEX idx_messages_session_time
            ON messages(sessionId, timestamp)
          ''');
          await db.execute('''
            CREATE TABLE sessions (
              sessionId TEXT PRIMARY KEY,
              contactId TEXT NOT NULL,
              keyVaultId TEXT NOT NULL,
              displayName TEXT NOT NULL,
              peerPublicKey TEXT NOT NULL,
              isTrusted INTEGER NOT NULL DEFAULT 0,
              lastMessage TEXT,
              lastMessageTime INTEGER,
              unreadCount INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      );
    }

    _changes.add(const SessionCleared(''));
  }

  Database get _database {
    if (_db == null) throw StateError('DB not initialized');
    return _db!;
  }

  // ── MESSAGE WRITES ─────────────────────────────────────────────────────

  Future<void> saveMessage(ChatMessageModel message) async {
    await _database.insert('messages', _messageToRow(message),
        conflictAlgorithm: ConflictAlgorithm.replace);
    _changes.add(MessageAdded(message.sessionId, message));
  }

  Future<void> insertOrUpdateMessage(ChatMessageModel message) async {
    final existing = await getMessage(message.messageId);
    await _database.insert('messages', _messageToRow(message),
        conflictAlgorithm: ConflictAlgorithm.replace);
    _changes.add(existing == null
        ? MessageAdded(message.sessionId, message)
        : MessageUpdated(message.sessionId, message));
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    await _database.update('messages', {'status': status},
        where: 'messageId = ?', whereArgs: [messageId]);

    final updated = await getMessage(messageId);
    if (updated != null) {
      _changes.add(MessageUpdated(updated.sessionId, updated));
    }
  }

  Future<void> clearChat(String sessionId) async {
    await _database.delete('messages',
        where: 'sessionId = ?', whereArgs: [sessionId]);
    _changes.add(SessionCleared(sessionId));
  }

  // ── MESSAGE READS ──────────────────────────────────────────────────────

  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final rows = await _database.query('messages',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC');
    return rows.map(_rowToMessage).toList();
  }

  Future<ChatMessageModel?> getMessage(String messageId) async {
    final rows = await _database.query('messages',
        where: 'messageId = ?', whereArgs: [messageId], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToMessage(rows.first);
  }

  /// First emission = full DB query, subsequent = incremental in‑memory only
  Stream<List<ChatMessageModel>> watchMessages(String sessionId) async* {
    final cache = await getMessages(sessionId);
    yield List.unmodifiable(cache);

    await for (final event in _changes.stream) {
      switch (event) {
        case MessageAdded(:final message, sessionId: final sid):
          if (sid != sessionId) continue;
          cache.add(message);
          yield List.unmodifiable(cache);

        case MessageUpdated(:final message, sessionId: final sid):
          if (sid != sessionId) continue;
          final idx =
              cache.indexWhere((m) => m.messageId == message.messageId);
          if (idx >= 0) {
            cache[idx] = message;
          } else {
            cache.add(message);
          }
          yield List.unmodifiable(cache);

        case SessionCleared(sessionId: final sid):
          if (sid != sessionId) continue;
          cache.clear();
          yield List.unmodifiable(cache);

      }
    }
  }

  // ── SESSION WRITES ─────────────────────────────────────────────────────

  Future<void> saveSession(ChatSessionModel session) async {
    await _database.insert('sessions', _sessionToRow(session),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSession(String sessionId) async {
    await _database.delete('sessions',
        where: 'sessionId = ?', whereArgs: [sessionId]);
  }

  // ── SESSION READS ──────────────────────────────────────────────────────

  Future<ChatSessionModel?> getSession(String sessionId) async {
    final rows = await _database.query('sessions',
        where: 'sessionId = ?', whereArgs: [sessionId], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToSession(rows.first);
  }

  Future<List<ChatSessionModel>> getAllSessions() async {
    final rows = await _database.query('sessions');
    return rows.map(_rowToSession).toList();
  }

  Stream<List<ChatSessionModel>> watchSessions() async* {
    yield await getAllSessions();
    await for (final _ in _changes.stream) {
      yield await getAllSessions();
    }
  }

  // ── MAPPERS ────────────────────────────────────────────────────────────

  Map<String, dynamic> _messageToRow(ChatMessageModel m) => {
        'messageId': m.messageId,
        'fromUser': m.from,
        'toUser': m.to,
        'sessionId': m.sessionId,
        'cipherText': m.cipherText,
        'nonce': m.nonce,
        'mac': m.mac,
        'plainText': m.plainText,
        'timestamp': m.timestamp,
        'status': m.status,
      };

  ChatMessageModel _rowToMessage(Map<String, dynamic> row) {
    return ChatMessageModel(
      messageId: row['messageId'] as String,
      from: row['fromUser'] as String,
      to: row['toUser'] as String,
      sessionId: row['sessionId'] as String,
      cipherText: row['cipherText'] as String,
      nonce: row['nonce'] as String,
      mac: row['mac'] as String,
      plainText: row['plainText'] as String?,
      timestamp: row['timestamp'] as int,
      status: row['status'] as String,
    );
  }

  Map<String, dynamic> _sessionToRow(ChatSessionModel s) => {
        'sessionId': s.sessionId,
        'contactId': s.contactId,
        'keyVaultId': s.keyVaultId,
        'displayName': s.displayName,
        'peerPublicKey': s.peerPublicKey,
        'isTrusted': s.isTrusted ? 1 : 0,
        'lastMessage': s.lastMessage,
        'lastMessageTime': s.lastMessageTime?.millisecondsSinceEpoch,
        'unreadCount': s.unreadCount,
      };

  ChatSessionModel _rowToSession(Map<String, dynamic> row) {
    return ChatSessionModel(
      sessionId: row['sessionId'] as String,
      contactId: row['contactId'] as String,
      keyVaultId: row['keyVaultId'] as String,
      displayName: row['displayName'] as String,
      peerPublicKey: row['peerPublicKey'] as String,
      isTrusted: (row['isTrusted'] as int) == 1,
      lastMessage: row['lastMessage'] as String?,
      lastMessageTime: row['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['lastMessageTime'] as int)
          : null,
      unreadCount: row['unreadCount'] as int,
    );
  }

  // ── CLEANUP ────────────────────────────────────────────────────────────

  Future<void> close() async {
    await _db?.close();
    await _changes.close();
    _db = null;
  }
}
