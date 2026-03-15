import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _currentUserId;

  void setCurrentUser(String userId) => _currentUserId = userId;

  String get currentUserId {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) return firebaseUser.uid;
    if (_currentUserId != null) return _currentUserId!;
    throw Exception("ChatService: no user logged in");
  }

  Future<Map<String, String?>> _fetchUserInfo(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      return {
        'name': data?['name'] as String?,
        'image': data?['profileImage'] as String?,
      };
    } catch (_) {
      return {'name': null, 'image': null};
    }
  }

  // ── 1. Get or create chat ──
  Future<String> getOrCreateChat({
    required String otherUserId,
    String? otherUserName,
    String? otherUserImage,
    String? createdFrom,
    String? sourceId,
  }) async {
    final existing = await _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        final data = doc.data() as Map<String, dynamic>;
        if ((data['otherUserName'] ?? '').toString().isEmpty) {
          final info = otherUserName != null
              ? {'name': otherUserName, 'image': otherUserImage}
              : await _fetchUserInfo(otherUserId);
          await doc.reference.set(
            {
              'otherUserName': info['name'] ?? '',
              'otherUserImage': info['image'],
            },
            SetOptions(merge: true),
          );
        }
        return doc.id;
      }
    }

    final info = otherUserName != null
        ? {'name': otherUserName, 'image': otherUserImage}
        : await _fetchUserInfo(otherUserId);

    final newChat = await _db.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdFrom': createdFrom,
      'sourceId': sourceId,
      'otherUserName': info['name'] ?? '',
      'otherUserImage': info['image'],
      // ✅ Initialize unread counts to 0 for both users
      'unreadCounts': {
        currentUserId: 0,
        otherUserId: 0,
      },
    });

    return newChat.id;
  }

  // ── 2. Send message — increments receiver's unread count ──
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String type,
    String? fileUrl,
  }) async {
    // ✅ Get the other participant to increment their unread count
    final chatDoc = await _db.collection('chats').doc(chatId).get();
    final participants =
        List<String>.from(chatDoc.data()?['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId,
            orElse: () => '');

    final batch = _db.batch();

    // Write message
    final msgRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': currentUserId,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'deleted': false,
      if (fileUrl != null) 'fileUrl': fileUrl,
    });

    // ✅ Update chat doc — increment receiver's unread count
    // FieldValue.increment is atomic — safe for concurrent writes
    batch.set(
      _db.collection('chats').doc(chatId),
      {
        'lastMessage': type == 'text' ? text : '📎 $type',
        'lastMessageTime': FieldValue.serverTimestamp(),
        if (otherUserId.isNotEmpty)
          'unreadCounts.$otherUserId': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ── 3. Upload file ──
  Future<String> uploadChatFile({
    required File file,
    required String chatId,
    required String type,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_files')
        .child(chatId)
        .child(type)
        .child(fileName);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ── 4. Clear chat ──
  Future<void> clearChat(String chatId) async {
    final messages = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'deleted': true});
    }
    await batch.commit();

    await _db.collection('chats').doc(chatId).set(
      {
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── 5. Messages stream ──
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromDoc(doc))
            .where((msg) => !msg.deleted)
            .toList());
  }

  // ── 6. Chats stream ──
  Stream<List<ChatModel>> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromDoc(doc))
            .toList());
  }

  // ── 7. Mark as read — resets current user's unread count ──
  Future<void> markMessagesAsRead(String chatId) async {
    final unread = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // ✅ Reset this user's unread count to 0
    batch.set(
      _db.collection('chats').doc(chatId),
      {'unreadCounts.$currentUserId': 0},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ── 8. Delete message ──
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'deleted': true});
  }
}