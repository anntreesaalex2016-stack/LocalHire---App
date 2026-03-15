import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import 'message_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  bool showUnreadOnly = false;
  String searchQuery = "";
  final int maxPinned = 3;
  final Set<String> pinnedChats = {};
  List<ChatModel> _lastKnownChats = [];

  String getOtherUserId(List<String> participants) {
    final currentUid = _chatService.currentUserId;
    return participants.firstWhere(
        (id) => id != currentUid, orElse: () => '');
  }

  void togglePin(String chatId) {
    if (!pinnedChats.contains(chatId) &&
        pinnedChats.length >= maxPinned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You can only pin up to 3 chats.")),
      );
      return;
    }
    setState(() {
      pinnedChats.contains(chatId)
          ? pinnedChats.remove(chatId)
          : pinnedChats.add(chatId);
    });
  }

  void showPinDialog(String chatId) {
    final isPinned = pinnedChats.contains(chatId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPinned ? "Unpin Chat" : "Pin Chat"),
        content: Text(isPinned
            ? "Do you want to unpin this chat?"
            : "Do you want to pin this chat?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              togglePin(chatId);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  List<ChatModel> _sortChats(List<ChatModel> chats) {
    final sorted = [...chats];
    sorted.sort((a, b) {
      final aPinned = pinnedChats.contains(a.id);
      final bPinned = pinnedChats.contains(b.id);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      final aTime = a.lastMessageTime ?? DateTime(2000);
      final bTime = b.lastMessageTime ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "LocalHire",
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) =>
                  setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search messages...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFE9E9E9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => showUnreadOnly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly
                              ? Colors.transparent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: Text("All")),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => showUnreadOnly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: Text("Unread")),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getUserChats(),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data!.isNotEmpty) {
                  _lastKnownChats = snapshot.data!;
                }

                final allChats = _lastKnownChats;

                if (allChats.isEmpty &&
                    snapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (allChats.isEmpty &&
                    snapshot.connectionState ==
                        ConnectionState.active) {
                  return const Center(
                    child: Text("No chats yet",
                        style: TextStyle(
                            color: Colors.grey, fontSize: 16)),
                  );
                }

                // ✅ Filter by unread using unreadCounts map
                final currentUid = _chatService.currentUserId;
                final filtered = showUnreadOnly
                    ? allChats
                        .where((c) => c.unreadFor(currentUid) > 0)
                        .toList()
                    : allChats;

                if (showUnreadOnly && filtered.isEmpty) {
                  return const Center(
                    child: Text("No unread messages",
                        style: TextStyle(
                            color: Colors.grey, fontSize: 16)),
                  );
                }

                final sorted = _sortChats(filtered);

                return ListView.builder(
                  key: PageStorageKey(
                      'chat_list_${showUnreadOnly ? "unread" : "all"}'),
                  itemCount: sorted.length,
                  addAutomaticKeepAlives: true,
                  itemBuilder: (context, index) {
                    final chat = sorted[index];
                    final otherUserId =
                        getOtherUserId(chat.participants);
                    final isPinned =
                        pinnedChats.contains(chat.id);
                    // ✅ Pass unread count to item for badge display
                    final unreadCount =
                        chat.unreadFor(currentUid);

                    return _ChatItem(
                      key: ValueKey(chat.id),
                      chat: chat,
                      otherUserId: otherUserId,
                      isPinned: isPinned,
                      searchQuery: searchQuery,
                      formatTime: _formatTime,
                      unreadCount: unreadCount,
                      onLongPress: () => showPinDialog(chat.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem extends StatefulWidget {
  final ChatModel chat;
  final String otherUserId;
  final bool isPinned;
  final String searchQuery;
  final String Function(DateTime?) formatTime;
  final VoidCallback onLongPress;
  final int unreadCount;

  const _ChatItem({
    super.key,
    required this.chat,
    required this.otherUserId,
    required this.isPinned,
    required this.searchQuery,
    required this.formatTime,
    required this.onLongPress,
    required this.unreadCount,
  });

  @override
  State<_ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<_ChatItem>
    with AutomaticKeepAliveClientMixin {

  static final Map<String, Map<String, String?>> _userCache = {};

  @override
  bool get wantKeepAlive => true;

  late String _name;
  late String? _image;
  bool _needsFetch = false;

  @override
  void initState() {
    super.initState();
    _resolveUser();
  }

  @override
  void didUpdateWidget(covariant _ChatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.otherUserName.isEmpty &&
        widget.chat.otherUserName.isNotEmpty) {
      setState(() {
        _name = widget.chat.otherUserName;
        _image = widget.chat.otherUserImage;
        _needsFetch = false;
        _userCache[widget.otherUserId] = {
          'name': _name,
          'profileImage': _image,
        };
      });
    }
  }

  void _resolveUser() {
    if (widget.chat.otherUserName.isNotEmpty) {
      _name = widget.chat.otherUserName;
      _image = widget.chat.otherUserImage;
      _userCache[widget.otherUserId] = {
        'name': _name,
        'profileImage': _image,
      };
      return;
    }

    if (_userCache.containsKey(widget.otherUserId)) {
      final c = _userCache[widget.otherUserId]!;
      _name = c['name'] ?? '';
      _image = c['profileImage'];
      return;
    }

    _name = '';
    _image = null;
    _needsFetch = true;
    _fetchAndBackfill();
  }

  Future<void> _fetchAndBackfill() async {
    if (widget.otherUserId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      final name = doc.data()?['name'] as String? ?? '';
      final image = doc.data()?['profileImage'] as String?;

      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .set(
            {'otherUserName': name, 'otherUserImage': image},
            SetOptions(merge: true),
          )
          .catchError((_) {});

      _userCache[widget.otherUserId] = {
        'name': name,
        'profileImage': image,
      };

      if (mounted) {
        setState(() {
          _name = name;
          _image = image;
          _needsFetch = false;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.searchQuery.isNotEmpty &&
        !_needsFetch &&
        !_name
            .toLowerCase()
            .contains(widget.searchQuery.toLowerCase())) {
      return const SizedBox.shrink();
    }

    final initial =
        _name.isNotEmpty ? _name[0].toUpperCase() : '?';

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageScreen(
              chatId: widget.chat.id,
              otherUserId: widget.otherUserId,
              userName: _name.isEmpty ? 'User' : _name,
              userProfileImage: _image,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFECE6D8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              backgroundImage: _image != null
                  ? NetworkImage(_image!)
                  : null,
              child: _image == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _name.isEmpty ? '' : _name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            // ✅ Bold name when unread
                            color: widget.unreadCount > 0
                                ? Colors.black
                                : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isPinned)
                        const Icon(Icons.push_pin,
                            size: 14, color: Colors.grey),
                      // ✅ Unread badge
                      if (widget.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4A825),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            widget.unreadCount > 99
                                ? '99+'
                                : '${widget.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.chat.lastMessage.isEmpty
                        ? "No messages yet"
                        : widget.chat.lastMessage,
                    style: TextStyle(
                      color: widget.unreadCount > 0
                          ? Colors.black54
                          : Colors.grey,
                      fontSize: 13,
                      // ✅ Slightly bolder preview when unread
                      fontWeight: widget.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              widget.formatTime(widget.chat.lastMessageTime),
              style: TextStyle(
                fontSize: 11,
                color: widget.unreadCount > 0
                    ? const Color(0xFFF4A825)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}