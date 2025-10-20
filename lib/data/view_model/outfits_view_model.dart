import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_outfits/data/firebase_servise/storage.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../util/common_bottom_sheet.dart';
import '../firebase_servise/firestore.dart';
import '../model/user_model.dart';
import 'comment_view_model.dart';

const String _DEFAULT_AVATAR_URL =
    'https://firebasestorage.googleapis.com/v0/b/myoutfits-937e9.firebasestorage.app/o/person.png?alt=media&token=204a0a4f-ecc3-4599-b9a9-0edda28ca308';

class OutfitsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final Firebase_Firestore _firestoreService = Firebase_Firestore();
  final StorageMethod _storageMethod = StorageMethod();

  /// Biến dữ liệu gốc (data từ Algolia hoặc Firestore)
  Map<String, dynamic> currentOutfit;

  String? _currentPostId;
  String? _currentOwnerId;

  UserModel? creatorUser;
  int _likesCount = 0;
  int _commentsCount = 0;
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isLiked = false;
  bool _isDeleted = false;

  List<Map<String, dynamic>> _otherUserOutfits = [];
  List<Map<String, dynamic>> _similarOutfits = [];

  List<Map<String, dynamic>> get otherUserOutfits => _otherUserOutfits;
  List<Map<String, dynamic>> get similarOutfits => _similarOutfits;
  bool get isFollowing => _isFollowing;
  bool get isLoading => _isLoading;
  bool get isSaved => _isSaved;
  bool get isLiked => _isLiked;
  bool get isDeleted => _isDeleted;
  int get likesCount => _likesCount;
  int get commentsCount => _commentsCount;
  String? get currentUserId => _currentUserId;

  StreamSubscription? _likesSub;
  StreamSubscription? _commentsSub;
  StreamSubscription? _likedSub;
  StreamSubscription? _savedSub;

  OutfitsViewModel(this.currentOutfit) {
    debugPrint('--- [OutfitsViewModel Init] ---');
    debugPrint('Outfit Data Keys: ${currentOutfit.keys}');
    debugPrint('currentUser ID: $_currentUserId');
    debugPrint('Source Post ID: ${currentOutfit['postId']}');
    debugPrint('Source Outfit ID: ${currentOutfit['outfitID']}');
    debugPrint('Source Owner ID: ${currentOutfit['ownerID']}');
    debugPrint('Algolia objectID: ${currentOutfit['objectID']}');
    debugPrint('-------------------------------');

    _likesCount = currentOutfit['likesCount'] as int? ?? 0;
    _commentsCount = currentOutfit['commentsCount'] as int? ?? 0;

    _currentPostId =
        currentOutfit['postId'] as String? ??
        currentOutfit['objectID'] as String?;

    _currentOwnerId = currentOutfit['ownerID'] as String?;

    _loadDataBasedOnSource();
  }

  @override
  void dispose() {
    _likesSub?.cancel();
    _commentsSub?.cancel();
    _likedSub?.cancel();
    _savedSub?.cancel();
    super.dispose();
  }

  void _listenRealtime() {
    final String? postId = _currentPostId;
    if (postId == null) return;
    _likesSub = _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .snapshots()
        .listen((snapshot) {
          if (_likesCount != snapshot.docs.length) {
            _likesCount = snapshot.docs.length;
            notifyListeners();
          }
        });
    _commentsSub = _firebaseFirestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .listen((snapshot) {
          if (_commentsCount != snapshot.docs.length) {
            _commentsCount = snapshot.docs.length;
            notifyListeners();
          }
        });
    if (_currentUserId != null) {
      _likedSub = _firebaseFirestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(_currentUserId)
          .snapshots()
          .listen((doc) {
            _isLiked = doc.exists;
            notifyListeners();
          });
      _savedSub = _firebaseFirestore
          .collection('saved')
          .doc(_currentUserId!)
          .collection('user_save')
          .doc(postId)
          .snapshots()
          .listen((doc) {
            _isSaved = doc.exists;
            notifyListeners();
          });
    }
  }

  Future<void> _loadDataBasedOnSource() async {
    _isLoading = true;
    notifyListeners();
    if (_currentPostId == null) {
      _currentPostId =
          currentOutfit['postId'] as String? ??
          currentOutfit['objectID'] as String?;
    }
    if (_currentOwnerId == null && _currentPostId != null) {
      debugPrint(
        "⚠️ Dữ liệu thiếu ownerID. Đang kiểm tra lại Post từ Firestore...",
      );
      DocumentSnapshot postDoc = await _firebaseFirestore
          .collection('posts')
          .doc(_currentPostId!)
          .get();
      if (!postDoc.exists) {
        String? gender =
            currentOutfit['gender'] as String? ??
            currentOutfit['ownerGender'] as String?;

        if (gender != null && (gender == 'man' || gender == 'woman')) {
          debugPrint(
            "⚠️ Post không tồn tại trong 'posts', đang thử Fallback sang 'outfits/$gender/1'.",
          );
          try {
            postDoc = await _firebaseFirestore
                .collection('outfits')
                .doc(gender)
                .collection('1')
                .doc(_currentPostId!)
                .get();
          } catch (e) {
            debugPrint("❌ Lỗi khi Fallback Outfit: $e");
          }
        }
      }
      if (postDoc.exists) {
        currentOutfit = postDoc.data() as Map<String, dynamic>;
        _currentOwnerId = currentOutfit['ownerID'] as String?;
        currentOutfit['postId'] = _currentPostId;
        debugPrint(
          "✅ Đã fetch thành công Post data từ Firestore (Source: ${postDoc.reference.parent.id == 'posts' ? 'posts' : 'outfits'}).",
        );
      } else {
        await _tryFindPostIdByImageURL();
        if (_currentPostId == null) {
          debugPrint(
            "❌ Không tìm thấy bài viết Post $_currentPostId (hoặc qua imageURL).",
          );
          _isDeleted = true;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    }

    /// Kiểm tra tính hợp lệ cuối cùng
    if (_currentPostId == null) {
      debugPrint("Không thể xác định Post ID hoặc Owner ID.");
      _isLoading = false;
      _isDeleted = true;
      notifyListeners();
      return;
    }

    /// LẤY SỐ LƯỢNG LIKES VÀ COMMENTS HIỆN TẠI TỪ FIRESTORE
    try {
      /// Chỉ đếm likes/comments trên collection 'posts'
      final likesSnap = await _firebaseFirestore
          .collection('posts')
          .doc(_currentPostId!)
          .collection('likes')
          .count()
          .get();
      _likesCount = likesSnap.count!;
      final commentsSnap = await _firebaseFirestore
          .collection('posts')
          .doc(_currentPostId!)
          .collection('comments')
          .count()
          .get();
      _commentsCount = commentsSnap.count!;
      currentOutfit['likesCount'] = _likesCount;
      currentOutfit['commentsCount'] = _commentsCount;
      debugPrint("⚡ Likes Count ban đầu: $_likesCount");
    } catch (e) {
      debugPrint("❌ Lỗi khi đếm Likes/Comments: $e");
      _likesCount = currentOutfit['likesCount'] as int? ?? 0;
      _commentsCount = currentOutfit['commentsCount'] as int? ?? 0;
    }

    ///Khởi tạo lắng nghe thời gian thực sau khi có ID chắc chắn
    _listenRealtime();

    /// Tải dữ liệu còn lại
    await _loadCreatorData();
    await _checkIfSaved();
    await _checkIfLiked();
    await _loadRelatedOutfits;
    if (_currentOwnerId != null && _currentPostId != null) {
      await _loadRelatedOutfits(
        _currentOwnerId!,
        _currentPostId!,
        List<String>.from(currentOutfit['allTags'] ?? []),
        currentOutfit['type'] != 'outfit',
      );
    } else {
      _similarOutfits = await loadSimilarStyleOutfit(
        List<String>.from(currentOutfit['allTags'] ?? []),
        currentOutfit['type'] != 'outfit',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _tryFindPostIdByImageURL() async {
    final List<String> imageUrls = currentOutfit['imageURLs'] != null
        ? List<String>.from(currentOutfit['imageURLs'])
        : (currentOutfit['imageURL'] != null
              ? [currentOutfit['imageURL'] as String]
              : []);
    if (imageUrls.isEmpty) return;
    debugPrint("⚠️ Thử tìm Post ID bằng Image URL: ${imageUrls.first}");
    try {
      final querySnapshot = await _firebaseFirestore
          .collection('posts')
          .where('imageURLs', arrayContainsAny: imageUrls)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final postDoc = querySnapshot.docs.first;
        currentOutfit = postDoc.data();
        _currentPostId = postDoc.id;
        _currentOwnerId = currentOutfit['ownerID'] as String?;
        currentOutfit['postId'] = _currentPostId;
        debugPrint("✅ Tìm thấy Post ID: $_currentPostId qua ImageURL!");
        return;
      }
    } catch (e) {
      debugPrint("❌ Lỗi khi tìm Post ID bằng ImageURL: $e");
    }
    try {
      const List<String> genders = ['man', 'woman'];
      for (String gender in genders) {
        final outfitQuery = await _firebaseFirestore
            .collection('outfits')
            .doc(gender)
            .collection('1')
            .where('imageURLs', arrayContainsAny: imageUrls)
            .limit(1)
            .get();

        if (outfitQuery.docs.isNotEmpty) {
          final outfitDoc = outfitQuery.docs.first;
          currentOutfit = outfitDoc.data();
          _currentPostId = outfitDoc.id;
          _currentOwnerId = currentOutfit['ownerID'] as String?;
          currentOutfit['postId'] = _currentPostId;
          debugPrint(
            "✅ Tìm thấy Post ID: $_currentPostId qua ImageURL trong 'outfits/$gender/1'!",
          );
          return;
        }
      }
    } catch (e) {
      debugPrint("❌ Lỗi khi tìm Post ID bằng ImageURL trong 'outfits': $e");
    }
  }

  Future<void> _loadAllData() async {
    await _loadDataBasedOnSource();
  }

  Future<void> _checkIfSaved() async {
    final String? postId = _currentPostId;
    if (_currentUserId == null || postId == null) {
      _isSaved = false;
      return;
    }
    try {
      _isSaved = await _firestoreService.isOutfitSaved(postId);
      debugPrint('isSaved = $_isSaved');
    } catch (e) {
      print('Lỗi $e');
      _isSaved = false;
    }
  }

  Future<void> _checkIfLiked() async {
    final String? postId = _currentPostId;
    if (_currentUserId == null || postId == null) {
      _isLiked = false;
      return;
    }
    try {
      final likedDoc = await _firebaseFirestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(_currentUserId)
          .get();
      _isLiked = likedDoc.exists;
      debugPrint('isLiked = $_isLiked');
    } catch (e) {
      print('Lỗi $e');
      _isLiked = false;
    }
  }

  Future<void> _loadCreatorData() async {
    try {
      String? creatorId = _currentOwnerId;
      debugPrint("👉 ownerID trong outfit: $creatorId");
      debugPrint("👉 currentUser.uid: $_currentUserId");

      if (creatorId == null) {
        creatorUser = UserModel(
          uid: '',
          username: 'Người dùng ẩn danh',
          styles: [],
          following: [],
          followers: [],
          profile: _DEFAULT_AVATAR_URL,
        );
        return;
      }
      creatorUser = await _firestoreService.getUserInfo(creatorId);
      if (creatorUser == null) {
        debugPrint("❌ Không tìm thấy user với id: $creatorId");
        creatorUser = UserModel(
          uid: '',
          username: 'Người dùng ẩn danh',
          following: [],
          styles: [],
          followers: [],
          profile: _DEFAULT_AVATAR_URL,
        );
      } else {
        debugPrint("✅ Đã load creatorUser: ${creatorUser!.username}");
      }

      /// Kiểm tra xem currentUser có follow creator không
      if (_currentUserId != null && creatorId != _currentUserId) {
        final currentUser = await _firestoreService.getUserInfo(
          _currentUserId!,
        );
        if (currentUser != null) {
          _isFollowing = currentUser.following.contains(creatorId);
          debugPrint("🔎 isFollowing = $_isFollowing");
        }
      }
    } catch (e) {
      print('Lỗi khi tải dữ liệu người tạo: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllOutfits() async {
    List<Map<String, dynamic>> results = [];
    final genders = ["woman", "man"];

    for (String gender in genders) {
      final snap = await FirebaseFirestore.instance
          .collection("outfits")
          .doc(gender)
          .collection("1")
          .get();

      results.addAll(
        snap.docs.map((doc) {
          final data = doc.data();
          data['outfitId'] = doc.id;
          data['gender'] = gender;
          return data;
        }),
      );
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchOutfitsFromRefs(
    List<DocumentReference> refs,
  ) async {
    if (refs.isEmpty) return [];

    List<Map<String, dynamic>> fetchedOutfits = [];

    for (var ref in refs) {
      try {
        final outfitDoc = await ref.get();
        if (outfitDoc.exists) {
          final data = outfitDoc.data() as Map<String, dynamic>;

          data['outfitId'] = outfitDoc.id;
          data['postId'] = outfitDoc.id;
          fetchedOutfits.add(data);
        }
      } catch (e) {
        print("Lỗi khi tải bài viết từ reference: $e");
      }
    }
    return fetchedOutfits;
  }

  /// Tải các bài viết đã được người dùng lưu.
  Future<List<Map<String, dynamic>>> fetchSavedOutfits() async {
    if (_currentUserId == null) return [];

    try {
      final savedSnaps = await _firebaseFirestore
          .collection('saved')
          .doc(_currentUserId!)
          .collection('user_save')
          .orderBy('timestamp', descending: true)
          .get();

      List<DocumentReference> savedRefs = savedSnaps.docs
          .map((doc) => doc.data()?['postRef'] as DocumentReference)
          .where((ref) => ref != null)
          .toList();

      List<Map<String, dynamic>> savedOutfits = await _fetchOutfitsFromRefs(
        savedRefs,
      );
      return savedOutfits;
    } catch (e) {
      print('Lỗi khi tải bài viết đã lưu: $e');
      return [];
    }
  }

  /// Tải các bài viết đã được người dùng thích.
  Future<List<Map<String, dynamic>>> fetchLikedOutfits() async {
    if (_currentUserId == null) return [];

    try {
      final likedSnaps = await _firebaseFirestore
          .collection('liked')
          .doc(_currentUserId!)
          .collection('user_like')
          .orderBy('timestamp', descending: true)
          .get();

      List<DocumentReference> likedRefs = likedSnaps.docs
          .map((doc) => doc.data()?['postRef'] as DocumentReference)
          .where((ref) => ref != null)
          .toList();

      return await _fetchOutfitsFromRefs(likedRefs);
    } catch (e) {
      print('Lỗi khi tải bài viết đã thích: $e');
      return [];
    }
  }

  Future<void> _loadRelatedOutfits(
    String? ownerId,
    String? currentPostId,
    List<String> allTags,
    bool isFromPost,
  ) async {
    if (ownerId != null && currentPostId != null) {
      _otherUserOutfits = await loadOtherOutfitsFromSameUser(
        ownerId,
        currentPostId,
      );
    }
    _similarOutfits = await loadSimilarStyleOutfit(allTags, isFromPost);

    debugPrint("👥 OtherUserOutfits: ${_otherUserOutfits.length}");
    debugPrint("🎯 SimilarOutfits: ${_similarOutfits.length}");
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> loadOtherOutfitsFromSameUser(
    String ownerId,
    String currentPostId,
  ) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection('posts')
          .where('ownerID', isEqualTo: ownerId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final posts = querySnapshot.docs
          .where((doc) => doc.id != currentPostId)
          .map((doc) => {"postId": doc.id, ...doc.data()})
          .toList();

      return posts;
    } catch (e) {
      debugPrint("❌ loadOtherOutfitsFromSameUser error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadSimilarStyleOutfit(
    List<String> userTags,
    bool isFromPost,
  ) async {
    if (userTags.isEmpty) return [];
    try {
      List<Map<String, dynamic>> results = [];
      Set<String> processedPostIds = {};
      final postSnapshot = await _firebaseFirestore
          .collection('posts')
          .where('allTags', arrayContainsAny: userTags)
          .limit(20)
          .get();
      for (var doc in postSnapshot.docs) {
        final data = doc.data();
        final postId = doc.id;
        final allTags = List<String>.from(data['allTags'] ?? []);

        if (allTags.any((tag) => userTags.contains(tag)) &&
            !processedPostIds.contains(postId)) {
          results.add({"postId": doc.id, ...data});
          processedPostIds.add(postId);
        }
      }

      const List<String> genders = ['man', 'woman'];
      for (String gender in genders) {
        final outfitSnapshot = await _firebaseFirestore
            .collection('outfits')
            .doc(gender)
            .collection('1')
            .where('categories', arrayContainsAny: userTags)
            .limit(20)
            .get();
        for (var doc in outfitSnapshot.docs) {
          final data = doc.data();
          final postId = doc.id;
          final allTags = List<String>.from(data['allTags'] ?? []);

          if (allTags.any((tag) => userTags.contains(tag)) &&
              !processedPostIds.contains(postId)) {
            results.add({"postId": postId, "gender": gender, ...data});
            processedPostIds.add(postId);
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint("loadSimilarStyleOutfit error: $e");
      return [];
    }
  }

  Future<void> editOutfit(BuildContext context) async {
    final String? postId = _currentPostId;

    if (_currentOwnerId != _currentUserId || postId == null) {
      debugPrint('Không phải chủ sở hữu bài viết hoặc thiếu ID.');
      return;
    }
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.editpost,
      arguments: currentOutfit,
    );
    if (result == true) {
      // Sau khi chỉnh sửa, reload lại dữ liệu
      await _loadDataBasedOnSource();
    }
    debugPrint("✏️ Edit outfit: ${currentOutfit['outfitId']}");
  }

  Future<void> deleteOutfit() async {
    final String? outfitId = _currentPostId;
    final String? ownerId = _currentOwnerId;
    final String gender =
        currentOutfit['gender'] ?? currentOutfit['ownerGender'] ?? 'unknown';

    if (outfitId == null || ownerId == null || ownerId != _currentUserId) {
      debugPrint('không phải chủ sở hữu bài viết hoặc thiếu ID.');
      return;
    }

    try {
      // Xóa ảnh từ URL
      final List<String> imageUrls = List<String>.from(
        currentOutfit['imageURLs'] ?? [],
      );
      if (imageUrls.isNotEmpty) {
        await _storageMethod.deleteOutfitImages(imageUrls);
        debugPrint("🗑️ Đã xóa ảnh của outfit $outfitId trong Storage.");
      }

      // Xóa bài viết khỏi collection 'posts' (thử xóa, có thể không tồn tại)
      await _firebaseFirestore.collection("posts").doc(outfitId).delete();
      debugPrint("🗑️ Đã thử xóa outfit $outfitId khỏi (posts).");

      // Xóa bài viết khỏi collection 'outfits' (thử xóa, có thể không tồn tại)
      final outfitRef = _firebaseFirestore
          .collection("outfits")
          .doc(gender)
          .collection("1")
          .doc(outfitId);
      final outfitSnap = await outfitRef.get();
      if (outfitSnap.exists) {
        await outfitRef.delete();
        debugPrint("🗑️ Đã xóa outfit $outfitId khỏi (outfits/${gender}/1).");
      }

      debugPrint("🗑️ Đã hoàn tất xóa $outfitId");
      _isDeleted = true;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Lỗi khi xóa outfit: $e");
    }
  }

  void toggleFollow() async {
    if (_currentUserId == null ||
        creatorUser == null ||
        _currentUserId == creatorUser!.uid)
      return;

    try {
      DocumentReference currentUserRef = _firebaseFirestore
          .collection('users')
          .doc(_currentUserId);

      if (_isFollowing) {
        await currentUserRef.update({
          'following': FieldValue.arrayRemove([creatorUser!.uid]),
        });
        _isFollowing = false;
      } else {
        await currentUserRef.update({
          'following': FieldValue.arrayUnion([creatorUser!.uid]),
        });
        _isFollowing = true;
      }
      notifyListeners();
    } catch (e) {
      print('Lỗi khi theo dõi/hủy theo dõi: $e');
    }
  }

  Future<void> toggleLike() async {
    if (_currentPostId == null || _currentUserId == null) return;

    // 1. Cập nhật giao diện (Optimistic UI)
    final bool newIsLiked = !_isLiked;
    final int newLikesCount = _likesCount + (newIsLiked ? 1 : -1);

    _isLiked = newIsLiked;
    _likesCount = newLikesCount;
    notifyListeners();

    // 2. Thực hiện thao tác FireStore
    try {
      final docRef = _firebaseFirestore
          .collection('posts')
          .doc(_currentPostId!)
          .collection('likes')
          .doc(_currentUserId!);

      if (newIsLiked) {
        // Thêm document like
        await docRef.set({'timestamp': FieldValue.serverTimestamp()});
      } else {
        // Xóa document like
        await docRef.delete();
      }
      debugPrint('✅ Like status for $_currentPostId toggled to $newIsLiked');
    } catch (e) {
      // 3. Hoàn tác UI nếu có lỗi
      debugPrint('❌ Error toggling like status: $e');
      _isLiked = !newIsLiked; // Revert
      _likesCount = newLikesCount + (newIsLiked ? -1 : 1); // Revert count
      notifyListeners();
    }
  }

  Future<void> toggleSave() async {
    if (_currentPostId == null || _currentUserId == null) return;

    // 1. Cập nhật giao diện (Optimistic UI)
    final bool newIsSaved = !_isSaved;
    _isSaved = newIsSaved;
    notifyListeners();

    // 2. Thực hiện thao tác FireStore
    try {
      final docRef = _firebaseFirestore
          .collection('saved')
          .doc(_currentUserId!)
          .collection('user_save')
          .doc(_currentPostId!);

      if (newIsSaved) {
        // Lưu bài viết
        await docRef.set({
          'postRef': _firebaseFirestore
              .collection('posts')
              .doc(_currentPostId!),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Xóa bài viết đã lưu
        await docRef.delete();
      }
      debugPrint('✅ Save status for $_currentPostId toggled to $newIsSaved');
    } catch (e) {
      // 3. Hoàn tác UI nếu có lỗi
      debugPrint('❌ Error toggling save status: $e');
      _isSaved = !newIsSaved; // Revert
      notifyListeners();
    }
  }

  void updateCommentCount(int newCount) {
    if (_commentsCount != newCount) {
      _commentsCount = newCount;
      currentOutfit['commentsCount'] = _commentsCount;
      notifyListeners();
    }
  }

  void showCommentSheet(BuildContext context) {
    final String? postId = _currentPostId;

    if (postId == null) {
      debugPrint('❌ Không tìm thấy Post ID để mở Comment.');
      return;
    }
    final String? currentUserAvatarUrl = creatorUser?.profile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              // Truyền postId và currentUserAvatarUrl (dù nó sẽ được tải lại bên trong VM)
              create: (_) => CommentViewModel(
                postId: postId,
                initialUserAvatarUrl:
                    currentUserAvatarUrl, // SỬA LỖI: Truyền avatar đã có (nếu có)
              ),
            ),
            ChangeNotifierProvider<OutfitsViewModel>.value(value: this),
          ],

          child: CommentBottomSheet(
            postId: postId,
            onCommentCountUpdated: (count) => updateCommentCount(count),
          ),
        );
      },
    );
  }
}
