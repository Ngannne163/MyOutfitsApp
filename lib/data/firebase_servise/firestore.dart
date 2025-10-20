import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/comment_model.dart';
import '../model/user_model.dart';

class Firebase_Firestore {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> CreateUser({
    required String email,
    required String username,
    required String profile,
  }) async {
    await _firebaseFirestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .set({
          'email': email,
          'username': username,
          'profile': profile,
          'isFirstLogin': true,
          'styles': [],
          'followers': [],
          'following': [],
          'gender': [],
          'age': [],
          'height': [],
        }, SetOptions(merge: true));
    return true;
  }

  Future<UserModel?> getUserInfo(String uid) async {
    try {
      final doc = await _firebaseFirestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(uid, doc.data()!);
      }
    } catch (e) {
      print("Lỗi getUserInfo: $e");
    }
    return null;
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firebaseFirestore.collection('users').doc(uid).get();
  }

  Future<void> saveGoogleUser(User user) async {
    try {
      final uid = user.uid;
      final docSnapshot = await _firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();

      /// duyệt qua providerData để lấy info Google
      if (!docSnapshot.exists ||
          (docSnapshot.data()?['isFirstLogin'] ?? true)) {
        for (final providerProfile in user.providerData) {
          if (providerProfile.providerId == "google.com") {
            final uid = user.uid;

            /// Firebase UID duy nhất
            final name = providerProfile.displayName ?? "";
            final email = providerProfile.email ?? "";
            final photo = providerProfile.photoURL ?? "";

            /// lưu vào Firestore
            await _firebaseFirestore.collection('users').doc(uid).set({
              'email': email,
              'username': name,
              'profile': photo,
              'provider': 'google',
              'followers': [],
              'following': [],
              'isFirstLogin': true,

              /// flag cho câu hỏi trắc nghiệm
            }, SetOptions(merge: true));

            /// merge để không ghi đè toàn bộ
          }
        }
      }
    } catch (e) {
      print(" Lỗi lưu Google User: $e");
    }
  }

  Future<void> updateUserData() async {
    final doc = await _firebaseFirestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;

      Map<String, dynamic> updates = {};
      if (!data.containsKey('isFirstLogin')) {
        updates['isFirstLogin'] = false;
      }
      if (!data.containsKey('styles')) {
        updates['styles'] = [];
      }
      if (!data.containsKey('gender')) {
        updates['gender'] = [];
      }
      if (!data.containsKey('age')) {
        updates['age'] = [];
      }
      if (!data.containsKey('height')) {
        updates['height'] = [];
      }
      if (updates.isNotEmpty) {
        await doc.reference.update(updates);
      }
    }
  }

  Future<void> updateProfileData({
    required String username,
    required String nickname,
    required String profileUrl,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firebaseFirestore.collection('users').doc(uid).set({
      'username': username,
      'nickname': nickname,
      'profile': profileUrl,
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getOutfits(String gender) async {
    final snapshot = await _firebaseFirestore
        .collection('outfits')
        .doc(gender)
        .collection('1')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveQuizResult({
    required int age,
    required int height,
    required String gender,
    required List<String> selectedStyles,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firebaseFirestore.collection('users').doc(uid).set({
      'age': age,
      'height': height,
      'gender': gender,
      'styles': selectedStyles,
      'isFirstLogin': false,
    }, SetOptions(merge: true));
  }

  Future<void> createPost({
    required List<String> imageURLs,
    required String description,
    required List<String> styleTags,
    required List<String> placeTags,
    required List<String> seasonTags,
    required List<String> customHashtags,
  }) async {
    final uid = _auth.currentUser!.uid;
    final postId = FirebaseFirestore.instance.collection('posts').doc().id;

    /// Lấy thông tin user (để lấy height, gender, etc. nếu cần)
    final userDoc = await getUserData(uid);
    final userData = userDoc.data() as Map<String, dynamic>?;

    await _firebaseFirestore.collection('posts').doc(postId).set({
      'postId': postId,
      'ownerID': uid,
      'imageURLs': imageURLs,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
      'customHashtags': customHashtags,

      /// Gộp tất cả tags lại để dễ truy vấn (quan trọng cho Feed & AI)
      'allTags': [...styleTags, ...placeTags, ...seasonTags, ...customHashtags],

      /// Lưu trữ các tags riêng biệt
      'styleTags': styleTags,
      'placeTags': placeTags,
      'seasonTags': seasonTags,

      /// Thêm thông tin người đăng (để dễ lọc)
      'ownerHeight': userData?['height'] ?? 0,
      'ownerGender': userData?['gender'] ?? 'unknown',
    });
  }

  Future<void> updatePost({
    required String postId,
    required List<String> newImageURLs,
    required String description,
    required List<String> styleTags,
    required List<String> placeTags,
    required List<String> seasonTags,
    required List<String> customHashtags,
  }) async {
    final allTags = [
      ...styleTags,
      ...placeTags,
      ...seasonTags,
      ...customHashtags,
    ];

    await _firebaseFirestore.collection('posts').doc(postId).update({
      'imageURLs': newImageURLs, // Cập nhật danh sách ảnh
      'description': description,
      'timestamp':
          FieldValue.serverTimestamp(), // Cập nhật timestamp để đưa lên đầu
      'customHashtags': customHashtags,
      'allTags': allTags,
      'styleTags': styleTags,
      'placeTags': placeTags,
      'seasonTags': seasonTags,
      // Không cần cập nhật ownerID, ownerHeight, ownerGender
    });
  }

  Future<void> updateUserLikedTags(
    List<String> tags, {
    required bool increment,
  }) async {
    final uid = _auth.currentUser!.uid;
    final userRef = _firebaseFirestore.collection('users').doc(uid);

    final incrementValue = increment ? 1 : -1;

    Map<String, dynamic> updateMap = {};
    for (var tag in tags) {
      if (tag.isNotEmpty) {
        updateMap['likedTags.$tag'] = FieldValue.increment(incrementValue);
      }
    }
    if (updateMap.isNotEmpty)
      try {
        await userRef.update(updateMap);
      } catch (e) {
        await userRef.set({'likedTags': {}}, SetOptions(merge: true));
        await userRef.update(updateMap);
      }
  }

  Future<bool> isOutfitSaved(String postId) async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firebaseFirestore
        .collection('saved')
        .doc(uid)
        .collection('user_save')
        .doc(postId)
        .get();
    return doc.exists;
  }

  Future<void> saveOutfit(
    String ownerID,
    String postId,
    String ownerGender,
  ) async {
    final uid = _auth.currentUser!.uid;
    final postRef = _firebaseFirestore.collection('posts').doc(postId);
    await _firebaseFirestore
        .collection('saved')
        .doc(uid)
        .collection('user_save')
        .doc(postId)
        .set({
          'timestamp': FieldValue.serverTimestamp(),
          'ownerID': ownerID,
          'postRef': postRef,
        });
  }

  Future<void> removeSaveOutfit(String postId) async {
    final uid = _auth.currentUser!.uid;

    await _firebaseFirestore
        .collection('saved')
        .doc(uid)
        .collection('user_save')
        .doc(postId)
        .delete();
  }

  Future<bool> isOutfitLiked(String postId) async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firebaseFirestore
        .collection('liked')
        .doc(uid)
        .collection('user_like')
        .doc(postId)
        .get();
    return doc.exists;
  }

  Future<void> likeOutfit(
    String postId,
    String ownerId,
    String ownerGender,
  ) async {
    final uid = _auth.currentUser!.uid;

    final postRef = _firebaseFirestore.collection('posts').doc(postId);

    await _firebaseFirestore.collection('posts').doc(postId).update({
      'likesCount': FieldValue.increment(1),
    });

    await _firebaseFirestore
        .collection('liked')
        .doc(uid)
        .collection('user_like')
        .doc(postId)
        .set({
          'timestamp': FieldValue.serverTimestamp(),
          'ownerID': ownerId,
          'postRef': postRef,
        });
  }

  Future<void> unlikeOutfit(String postId) async {
    final uid = _auth.currentUser!.uid;

    await _firebaseFirestore.collection('posts').doc(postId).update({
      'likesCount': FieldValue.increment(-1),
    });

    await _firebaseFirestore
        .collection('liked')
        .doc(uid)
        .collection('user_like')
        .doc(postId)
        .delete();
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _firebaseFirestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayUnion([targetUserId]),
    });

    await _firebaseFirestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId]),
    });
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _firebaseFirestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId]),
    });

    await _firebaseFirestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId]),
    });
  }

  Future<void> postComment({
    required String postId,
    required String content,
    required String currentUserId,
    required String username,
    String? userProfileUrl,
  }) async {
    final commentRef = _firebaseFirestore.collection('comments').doc();
    final commentId = commentRef.id;


    final commentData = {
      'commentId': commentId,
      'postId': postId,
      'userId': currentUserId,
      'username': username,
      'userProfileUrl': userProfileUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await commentRef.set(commentData);

    await _firebaseFirestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firebaseFirestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: false) // Sắp xếp theo thời gian cũ nhất
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<Map<String, dynamic>>> searchOutfits(String query, List<String> tags) async {
    final lowerQuery = query.toLowerCase().trim();
    List<Map<String, dynamic>> results = [];

    final postSearchTerms = <String>{...tags.map((tag) => tag.toLowerCase())};
    if (lowerQuery.isNotEmpty) {
      postSearchTerms.add(lowerQuery);
    }
    final postSearchList = postSearchTerms.toList();


    final outfitSearchTerms = <String>{...tags.map((tag) => tag.toLowerCase())};
    if (lowerQuery.isNotEmpty) {
      outfitSearchTerms.add(lowerQuery);
    }
    final outfitSearchList = outfitSearchTerms.toList();

    if (outfitSearchList.isEmpty) return [];
    if (outfitSearchList.length > 10) {
      print("Cảnh báo: Số lượng tags tìm kiếm vượt quá 10. Truy vấn có thể bị giới hạn.");
    }


    try {
      final postSnapshot = await _firebaseFirestore
          .collection('posts')
          .where('allTags', arrayContainsAny: postSearchList)
          .get();

      results.addAll(postSnapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        data['type'] = "post";
        return data;
      }));
    } catch (e) {
      print("Lỗi khi tìm kiếm trong 'posts': $e");
    }

    final genders = ["man", "woman"];
    for (final gender in genders) {
      try {
        final outfitSnapshot = await _firebaseFirestore
            .collection('outfits')
            .doc(gender)
            .collection('1')
            .where('categories', arrayContainsAny: outfitSearchList)
            .get();

        results.addAll(outfitSnapshot.docs.map((doc) {
          final data = doc.data();
          data['outfitId'] = doc.id;
          data['gender'] = gender;
          data['type'] = "categories";
          return data;
        }));
      } catch (e) {
        print("Lỗi khi tìm kiếm trong 'outfits/$gender/1': $e");
      }
    }

    final uniqueResults = <String, Map<String, dynamic>>{};
    for (var item in results) {
      final id = item['postId'] ?? item['outfitId'];
      if (id != null) uniqueResults[id] = item;
    }
    return uniqueResults.values.toList();
  }

  Future<Map<String, List<String>>> getSuggestionTags() async {
    final Set<String> uniqueCategories = {};
    final Set<String> uniquePlaces = {};

    final genders = ["man", "woman"];
    for (final gender in genders) {
      try {
        final snapshot = await _firebaseFirestore
            .collection('outfits')
            .doc(gender)
            .collection('1')
            .get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final categories = List<String>.from(data['categories'] ?? []);
          uniqueCategories.addAll(categories);
          final places = List<String>.from(data['places'] ?? []);
          uniquePlaces.addAll(places);
        }
      } catch (e) {
        print("Cảnh báo: Lỗi khi quét outfits mẫu để lấy tags ($gender): $e");
      }
    }
    return {
      'styles': uniqueCategories.toList(),
      'places': uniquePlaces.toList(),
    };
  }
}
