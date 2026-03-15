import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? createdFrom;
  final String? sourceId;
  final String otherUserName;
  final String? otherUserImage;
  // ✅ unreadCount is stored as a map per uid in Firestore
  // e.g. { "uid1": 3, "uid2": 0 }
  // We parse out the current user's count in chat_screen
  final Map<String, dynamic> unreadCounts;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageTime,
    this.createdFrom,
    this.sourceId,
    this.otherUserName = '',
    this.otherUserImage,
    this.unreadCounts = const {},
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdFrom: data['createdFrom'],
      sourceId: data['sourceId'],
      otherUserName: data['otherUserName'] ?? '',
      otherUserImage: data['otherUserImage'],
      unreadCounts: data['unreadCounts'] as Map<String, dynamic>? ?? {},
    );
  }

  // ✅ Helper — get unread count for a specific uid
  int unreadFor(String uid) {
    return (unreadCounts[uid] as int?) ?? 0;
  }
}