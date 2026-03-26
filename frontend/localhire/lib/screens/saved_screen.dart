import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import 'message_screen.dart';
import 'worker_profile_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  // 0 = By Name (among saved), 1 = By Skill (global search)
  int _searchMode = 0;
  String _searchQuery = '';

  // Skill search state
  bool _skillSearchLoading = false;
  List<Map<String, dynamic>> _skillResults = [];
  bool _skillSearchDone = false;

  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Start chat ──
  Future<void> _startChat(
      String uid, String name, String image) async {
    if (uid.isEmpty) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator()),
      );

      final chatId = await _chatService.getOrCreateChat(
        otherUserId: uid,
        otherUserName: name,
        otherUserImage: image,
        createdFrom: "saved_profile",
        sourceId: uid,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageScreen(
              chatId: chatId,
              otherUserId: uid,
              userName: name,
              userProfileImage: image.isNotEmpty ? image : null,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open chat: $e")),
        );
      }
    }
  }

  // ── Phone call ──
  Future<void> _callUser(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No phone number available")),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch dialler")),
        );
      }
    }
  }

  // ── Skill search: queries global users collection ──
  Future<void> _runSkillSearch(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _skillResults = [];
        _skillSearchDone = false;
      });
      return;
    }

    setState(() {
      _skillSearchLoading = true;
      _skillSearchDone = false;
    });

    try {
      // Firestore array-contains is case-sensitive, so we fetch all
      // users and do a client-side case-insensitive substring match on
      // their skills array.  For large datasets you can store a
      // lowercased copy of each skill and use array-contains instead.
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final results = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        // Skip own profile
        if (doc.id == _currentUid) continue;

        final data = doc.data();
        final skills = data['skills'];
        if (skills == null || skills is! List) continue;

        // Case-insensitive substring match against each skill string
        final matched = (skills as List).any((s) =>
            s.toString().toLowerCase().contains(q));

        if (matched) {
          results.add({
            'uid': doc.id,
            'name': data['name'] ?? 'User',
            'profileImage': data['profileImage'] ?? '',
            'phone': data['phone'] ?? data['phoneNumber'] ?? '',
            'location': data['location'] ?? '',
            'skills': skills,
          });
        }
      }

      if (mounted) {
        setState(() {
          _skillResults = results;
          _skillSearchLoading = false;
          _skillSearchDone = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _skillSearchLoading = false;
          _skillSearchDone = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Search failed: $e")),
        );
      }
    }
  }

  // ── Highlight matched skill chips ──
  List<String> _matchedSkills(List skills, String query) {
    final q = query.trim().toLowerCase();
    return skills
        .map((s) => s.toString())
        .where((s) => s.toLowerCase().contains(q))
        .toList();
  }

  List<String> _otherSkills(List skills, String query) {
    final q = query.trim().toLowerCase();
    return skills
        .map((s) => s.toString())
        .where((s) => !s.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Saved Profiles",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                setState(() => _searchQuery = v);
                // Live filter for name mode; debounce-free for skill mode
                if (_searchMode == 1) {
                  if (v.trim().isEmpty) {
                    setState(() {
                      _skillResults = [];
                      _skillSearchDone = false;
                    });
                  }
                }
              },
              onSubmitted: (v) {
                if (_searchMode == 1) _runSkillSearch(v);
              },
              textInputAction: _searchMode == 1
                  ? TextInputAction.search
                  : TextInputAction.done,
              decoration: InputDecoration(
                hintText: _searchMode == 0
                    ? "Search saved workers by name..."
                    : "Search all workers by skill  (e.g. plumber)",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchMode == 1 && _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward,
                            color: Color(0xFFF4A825)),
                        tooltip: "Search",
                        onPressed: () =>
                            _runSkillSearch(_searchController.text),
                      )
                    : (_searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _skillResults = [];
                                _skillSearchDone = false;
                              });
                            },
                          )
                        : null),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Mode toggle ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // By Name
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchMode = 0;
                          _searchController.clear();
                          _searchQuery = '';
                          _skillResults = [];
                          _skillSearchDone = false;
                        });
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _searchMode == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text("By Name",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  // By Skill
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchMode = 1;
                          _searchController.clear();
                          _searchQuery = '';
                          _skillResults = [];
                          _skillSearchDone = false;
                        });
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _searchMode == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text("By Skill",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Body ──
          Expanded(
            child: _searchMode == 0
                ? _buildSavedList()
                : _buildSkillSearchBody(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Mode 0 – Saved profiles filtered by name
  // ─────────────────────────────────────────────────────────────
  Widget _buildSavedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid!)
          .collection('saved_profiles')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No saved profiles yet",
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name =
              (data['name'] ?? '').toString().toLowerCase();
          if (_searchQuery.isEmpty) return true;
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text("No results found",
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data =
                docs[index].data() as Map<String, dynamic>;
            final uid = data['uid'] as String? ?? '';
            final name = data['name'] as String? ?? 'User';
            final image = data['profileImage'] as String? ?? '';

            return _SavedCard(
              uid: uid,
              name: name,
              image: image,
              onChat: () => _startChat(uid, name, image),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WorkerProfileScreen(userId: uid),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Mode 1 – Skill search body
  // ─────────────────────────────────────────────────────────────
  Widget _buildSkillSearchBody() {
    // Initial state — no search yet
    if (!_skillSearchDone && !_skillSearchLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Search for a skill to find workers",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              "e.g. plumber, electrician, painter",
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Loading
    if (_skillSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // No results
    if (_skillResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No workers found for "${_searchQuery.trim()}"',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Results
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            "${_skillResults.length} worker${_skillResults.length == 1 ? '' : 's'} found for \"${_searchQuery.trim()}\"",
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _skillResults.length,
            itemBuilder: (context, index) {
              final worker = _skillResults[index];
              final uid = worker['uid'] as String;
              final name = worker['name'] as String;
              final image = worker['image'] as String? ??
                  worker['profileImage'] as String? ??
                  '';
              final phone = worker['phone'] as String? ?? '';
              final location = worker['location'] as String? ?? '';
              final allSkills = worker['skills'] as List? ?? [];

              final matched =
                  _matchedSkills(allSkills, _searchQuery);
              final others = _otherSkills(allSkills, _searchQuery);

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkerProfileScreen(userId: uid),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: avatar + name/location + action btns ──
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: image.isNotEmpty
                                ? NetworkImage(image)
                                : null,
                            child: image.isEmpty
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight:
                                            FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Name + location
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                if (location.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 13,
                                          color: Colors
                                              .grey.shade500),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey
                                                  .shade500),
                                          overflow: TextOverflow
                                              .ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Chat button
                          GestureDetector(
                            onTap: () =>
                                _startChat(uid, name, image),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4A825),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.message,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Call button
                          GestureDetector(
                            onTap: () => _callUser(
                                phone.isNotEmpty ? phone : null),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: phone.isNotEmpty
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.call,
                                  color: phone.isNotEmpty
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                  size: 20),
                            ),
                          ),
                        ],
                      ),

                      // ── Skills row ──
                      if (allSkills.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            // Matched skills — highlighted
                            ...matched.map(
                              (s) => Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4A825),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ),
                            ),
                            // Other skills — muted
                            ...others.take(4).map(
                              (s) => Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.grey.shade300),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                      color:
                                          Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                            if (others.length > 4)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "+${others.length - 4} more",
                                  style: TextStyle(
                                      color:
                                          Colors.grey.shade500,
                                      fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Saved profile card (used in By Name mode)
// ─────────────────────────────────────────────────────────────
class _SavedCard extends StatelessWidget {
  final String uid;
  final String name;
  final String image;
  final VoidCallback onChat;
  final VoidCallback onTap;

  const _SavedCard({
    required this.uid,
    required this.name,
    required this.image,
    required this.onChat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFE8DD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  image.isNotEmpty ? NetworkImage(image) : null,
              child: image.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onChat,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4A825),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.message,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}