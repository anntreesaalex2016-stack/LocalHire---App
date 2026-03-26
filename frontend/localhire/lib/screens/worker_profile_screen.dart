import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'message_screen.dart';
import '../services/chat_service.dart';

// ─────────────────────────────────────────────────────────────
//  Helper: single review card (shared by profile & full list)
// ─────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isOwnReview;
  final VoidCallback? onEdit;

  const _ReviewCard({
    required this.review,
    this.isOwnReview = false,
    this.onEdit,
  });

  List<Widget> _buildStars(double rating) {
    return List.generate(5, (i) {
      if (rating >= i + 1) {
        return const Icon(Icons.star, color: Color(0xFFEFB04C), size: 14);
      } else if (rating >= i + 0.5) {
        return const Icon(Icons.star_half, color: Color(0xFFEFB04C), size: 14);
      } else {
        return const Icon(Icons.star_border, color: Color(0xFFEFB04C), size: 14);
      }
    });
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final fromUserId = review['fromUserId'] as String? ?? '';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['createdAt'] as Timestamp?;
    final updatedAt = review['updatedAt'] as Timestamp?;
    final displayTs = updatedAt ?? createdAt;
    final wasEdited = updatedAt != null;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .get(),
      builder: (context, snap) {
        final userData =
            snap.data?.data() as Map<String, dynamic>? ?? {};
        final reviewerName = userData['name'] as String? ?? 'User';
        final reviewerImage = userData['profileImage'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOwnReview
                ? const Color(0xFFFFF8EC)
                : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOwnReview
                  ? const Color(0xFFEFB04C).withOpacity(0.4)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: reviewerImage != null
                        ? NetworkImage(reviewerImage)
                        : null,
                    child: reviewerImage == null
                        ? Text(
                            reviewerName.isNotEmpty
                                ? reviewerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  // Name + timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isOwnReview ? 'You' : reviewerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            if (isOwnReview) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFB04C)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Your review',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFEFB04C),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _timeAgo(displayTs),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                            ),
                            if (wasEdited)
                              Text(
                                ' · edited',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Stars
                  Row(children: _buildStars(rating)),
                  // Edit button
                  if (isOwnReview && onEdit != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFEFB04C).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Color(0xFFEFB04C)),
                      ),
                    ),
                  ],
                ],
              ),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  comment,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black87, height: 1.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  All Reviews Screen
// ─────────────────────────────────────────────────────────────
class AllReviewsScreen extends StatelessWidget {
  final String workerId;
  final String workerName;
  final String currentUid;
  final VoidCallback onEditReview;

  const AllReviewsScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.currentUid,
    required this.onEditReview,
  });

  List<Widget> _buildStars(double rating) {
    return List.generate(5, (i) {
      if (rating >= i + 1) {
        return const Icon(Icons.star, color: Color(0xFFEFB04C), size: 18);
      } else if (rating >= i + 0.5) {
        return const Icon(Icons.star_half, color: Color(0xFFEFB04C), size: 18);
      } else {
        return const Icon(Icons.star_border, color: Color(0xFFEFB04C), size: 18);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "$workerName's Reviews",
          style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('toUserId', isEqualTo: workerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No reviews yet',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            );
          }

          final ratings = docs
              .map((d) =>
                  ((d.data() as Map<String, dynamic>)['rating'] as num)
                      .toDouble())
              .toList();
          final avg =
              ratings.reduce((a, b) => a + b) / ratings.length;

          // Count per star 5→1
          final barCounts = List.generate(
              5,
              (i) =>
                  ratings.where((r) => r.round() == (5 - i)).length);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Summary card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EFE6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          avg.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEFB04C),
                              height: 1),
                        ),
                        const SizedBox(height: 4),
                        Row(children: _buildStars(avg)),
                        const SizedBox(height: 4),
                        Text(
                          '${docs.length} review${docs.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: List.generate(5, (i) {
                          final star = 5 - i;
                          final count = barCounts[i];
                          final frac = docs.isEmpty
                              ? 0.0
                              : count / docs.length;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('$star',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star,
                                    size: 11,
                                    color: Color(0xFFEFB04C)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: frac,
                                      minHeight: 6,
                                      backgroundColor:
                                          Colors.grey.shade300,
                                      valueColor:
                                          const AlwaysStoppedAnimation<
                                                  Color>(
                                              Color(0xFFEFB04C)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 20,
                                  child: Text('$count',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.grey.shade600)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── All review cards ──
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final isOwn = data['fromUserId'] == currentUid;
                return _ReviewCard(
                  review: data,
                  isOwnReview: isOwn,
                  onEdit: isOwn
                      ? () {
                          Navigator.pop(context);
                          onEditReview();
                        }
                      : null,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Worker Profile Screen
// ─────────────────────────────────────────────────────────────
class WorkerProfileScreen extends StatefulWidget {
  final String userId;

  const WorkerProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final ChatService _chatService = ChatService();

  late final String _currentUid;
  late final DocumentReference _savedRef;

  // Increment to force FutureBuilder rebuilds after a review submit
  int _reviewKey = 0;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser!.uid;
    _savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .collection('saved_profiles')
        .doc(widget.userId);
  }

  // ── Save / unsave ──
  Future<void> _toggleSave(
      String name, String image, bool currentlySaved) async {
    try {
      if (currentlySaved) {
        await _savedRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Removed from saved profiles")));
        }
      } else {
        await _savedRef.set({
          'uid': widget.userId,
          'name': name,
          'profileImage': image,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile saved ✅")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // ── Start chat ──
  Future<void> _startChat(String name, String image) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator()),
      );
      final chatId = await _chatService.getOrCreateChat(
        otherUserId: widget.userId,
        otherUserName: name,
        otherUserImage: image,
        createdFrom: "worker_profile",
        sourceId: widget.userId,
      );
      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageScreen(
              chatId: chatId,
              otherUserId: widget.userId,
              userName: name,
              userProfileImage: image,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to open chat: $e")));
      }
    }
  }

  // ── Fetch jobs provided ──
  Future<int> _fetchJobsProvided() async {
    final snap = await FirebaseFirestore.instance
        .collection('jobs')
        .where('postedBy', isEqualTo: widget.userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ── Fetch review stats (avg + count) ──
  Future<Map<String, dynamic>> _fetchReviewStats() async {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('toUserId', isEqualTo: widget.userId)
        .get();
    if (snap.docs.isEmpty) return {'average': 0.0, 'count': 0};
    final total = snap.docs
        .map((d) => (d['rating'] as num).toDouble())
        .reduce((a, b) => a + b);
    return {
      'average': total / snap.docs.length,
      'count': snap.docs.length,
    };
  }

  // ── Fetch latest 3 reviews ──
  Future<List<QueryDocumentSnapshot>> _fetchLatestReviews() async {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('toUserId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();
    return snap.docs;
  }

  // ── Fetch current user's own review ──
  Future<DocumentSnapshot?> _fetchMyReview() async {
    final docId = '${_currentUid}_${widget.userId}';
    final doc = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(docId)
        .get();
    return doc.exists ? doc : null;
  }

  // ── Submit / update review ──
  Future<void> _submitReview({
    required double rating,
    required String comment,
    required String? jobId,
    required bool isEdit,
  }) async {
    final docId = '${_currentUid}_${widget.userId}';
    final ref =
        FirebaseFirestore.instance.collection('reviews').doc(docId);
    if (isEdit) {
      await ref.update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'fromUserId': _currentUid,
        'toUserId': widget.userId,
        'rating': rating,
        'comment': comment,
        'jobId': jobId ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Show add/edit bottom sheet ──
  void _showReviewSheet({DocumentSnapshot? existingReview}) {
    if (_currentUid == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You can't review yourself.")));
      return;
    }

    double selectedRating = existingReview != null
        ? (existingReview['rating'] as num).toDouble()
        : 0;
    final commentController = TextEditingController(
        text: existingReview != null
            ? existingReview['comment'] as String
            : '');
    final isEdit = existingReview != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEdit ? "Edit Your Review" : "Rate & Review",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                isEdit
                    ? "Update your rating and comment below."
                    : "Share your experience working with this person.",
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text("Your Rating",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (i) {
                  final val = (i + 1).toDouble();
                  return GestureDetector(
                    onTap: () =>
                        setModal(() => selectedRating = val),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        selectedRating >= val
                            ? Icons.star
                            : Icons.star_border,
                        color: const Color(0xFFEFB04C),
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
              if (selectedRating > 0) ...[
                const SizedBox(height: 6),
                Text(
                  _ratingLabel(selectedRating),
                  style: const TextStyle(
                      color: Color(0xFFEFB04C),
                      fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              const Text("Your Comment",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: "Write about your experience...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFEFB04C), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedRating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Please select a star rating.")));
                      return;
                    }
                    final comment =
                        commentController.text.trim();
                    if (comment.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Please write a comment.")));
                      return;
                    }
                    try {
                      await _submitReview(
                        rating: selectedRating,
                        comment: comment,
                        jobId: existingReview?['jobId'] as String?,
                        isEdit: isEdit,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        setState(() => _reviewKey++);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(isEdit
                                    ? "Review updated ✅"
                                    : "Review submitted ✅")));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Error: $e")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFB04C),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEdit ? "Update Review" : "Submit Review",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 5) return "Excellent";
    if (r >= 4) return "Very Good";
    if (r >= 3) return "Good";
    if (r >= 2) return "Fair";
    return "Poor";
  }

  List<Widget> _buildStars(double rating) {
    return List.generate(5, (i) {
      if (rating >= i + 1) {
        return const Icon(Icons.star, color: Color(0xFFEFB04C));
      } else if (rating >= i + 0.5) {
        return const Icon(Icons.star_half, color: Color(0xFFEFB04C));
      } else {
        return const Icon(Icons.star_border, color: Color(0xFFEFB04C));
      }
    });
  }

  // ── Open full reviews screen ──
  void _openAllReviews(String workerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllReviewsScreen(
          workerId: widget.userId,
          workerName: workerName,
          currentUid: _currentUid,
          onEditReview: () async {
            final myReview = await _fetchMyReview();
            if (mounted) _showReviewSheet(existingReview: myReview);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Worker Profile",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _savedRef.snapshots(),
        builder: (context, savedSnap) {
          final isSaved = savedSnap.data?.exists ?? false;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .get(),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final data =
                  profileSnap.data!.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'User';
              final location = data['location'] ?? 'Unknown';
              final about = data['about'] ?? '';
              final image = data['profileImage'] ??
                  'https://randomuser.me/api/portraits/men/32.jpg';

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // ── Profile image ──
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(image),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEFB04C)),
                            child: const Icon(Icons.verified,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(name,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(location,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Action buttons ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _toggleSave(name, image, isSaved),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.green, width: 2),
                              color: isSaved
                                  ? Colors.green.withOpacity(0.10)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isSaved ? "Saved" : "Save",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _startChat(name, image),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFFEFB04C),
                                  width: 2),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.message,
                                    color: Color(0xFFEFB04C)),
                                SizedBox(width: 8),
                                Text("Message",
                                    style: TextStyle(
                                        color: Color(0xFFEFB04C),
                                        fontWeight:
                                            FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Share.share(
                              "Check out this worker on LocalHire 👇\n\nlocalhire://profile/${widget.userId}"),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2),
                            ),
                            child: Icon(Icons.share,
                                color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ── About ──
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("About",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(about,
                          style: const TextStyle(
                              color: Colors.black87, height: 1.6)),
                    ),

                    const SizedBox(height: 25),

                    // ── Stats ──
                    FutureBuilder<int>(
                      future: _fetchJobsProvided(),
                      builder: (context, jobsSnap) {
                        final jobsProvided =
                            jobsSnap.data?.toString() ?? '—';
                        return Row(
                          children: [
                            Expanded(
                                child: _statCard(
                                    jobsProvided, "JOBS PROVIDED")),
                            const SizedBox(width: 15),
                            Expanded(
                                child:
                                    _statCard("—", "JOBS COMPLETED")),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // ── Rating summary + Add/Edit button ──
                    FutureBuilder<Map<String, dynamic>>(
                      key: ValueKey('stats_$_reviewKey'),
                      future: _fetchReviewStats(),
                      builder: (context, reviewSnap) {
                        final avg = reviewSnap.hasData
                            ? (reviewSnap.data!['average'] as double)
                            : 0.0;
                        final count = reviewSnap.hasData
                            ? reviewSnap.data!['count'] as int
                            : 0;
                        final avgDisplay = avg == 0.0
                            ? "—"
                            : avg.toStringAsFixed(1);

                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Rating",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                if (_currentUid != widget.userId)
                                  FutureBuilder<DocumentSnapshot?>(
                                    key: ValueKey(
                                        'myreview_btn_$_reviewKey'),
                                    future: _fetchMyReview(),
                                    builder: (context, mySnap) {
                                      final hasReview =
                                          mySnap.connectionState ==
                                                  ConnectionState
                                                      .done &&
                                              mySnap.data != null;
                                      return TextButton.icon(
                                        onPressed: () =>
                                            _showReviewSheet(
                                                existingReview:
                                                    hasReview
                                                        ? mySnap.data
                                                        : null),
                                        icon: Icon(
                                          hasReview
                                              ? Icons.edit
                                              : Icons
                                                  .rate_review_outlined,
                                          size: 18,
                                          color:
                                              const Color(0xFFEFB04C),
                                        ),
                                        label: Text(
                                          hasReview
                                              ? "Edit Review"
                                              : "Add Review",
                                          style: const TextStyle(
                                              color:
                                                  Color(0xFFEFB04C),
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ..._buildStars(avg),
                                const SizedBox(width: 10),
                                Text(avgDisplay,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Text("($count reviews)",
                                    style: const TextStyle(
                                        color: Colors.grey)),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Latest 3 reviews ──
                    FutureBuilder<List<QueryDocumentSnapshot>>(
                      key: ValueKey('reviews_$_reviewKey'),
                      future: _fetchLatestReviews(),
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          );
                        }

                        final docs = snap.data ?? [];
                        final myDocId =
                            '${_currentUid}_${widget.userId}';

                        if (docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text("No reviews yet",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14)),
                                if (_currentUid !=
                                    widget.userId) ...[
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        _showReviewSheet(),
                                    child: const Text(
                                      "Be the first to review",
                                      style: TextStyle(
                                        color: Color(0xFFEFB04C),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Review cards
                            ...docs.map((doc) {
                              final data = doc.data()
                                  as Map<String, dynamic>;
                              final isOwn = doc.id == myDocId;
                              return _ReviewCard(
                                review: data,
                                isOwnReview: isOwn,
                                onEdit: isOwn
                                    ? () async {
                                        final myReview =
                                            await _fetchMyReview();
                                        if (mounted) {
                                          _showReviewSheet(
                                              existingReview:
                                                  myReview);
                                        }
                                      }
                                    : null,
                              );
                            }),

                            // ── Show all reviews button ──
                            if (docs.length >= 3)
                              GestureDetector(
                                onTap: () =>
                                    _openAllReviews(name),
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(
                                                0xFFEFB04C)
                                            .withOpacity(0.5),
                                        width: 1.5),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Show all reviews",
                                        style: TextStyle(
                                          color: Color(0xFFEFB04C),
                                          fontWeight:
                                              FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward,
                                          color: Color(0xFFEFB04C),
                                          size: 16),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(number,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEFB04C))),
          const SizedBox(height: 5),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }
}