import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// --- Trạng thái (State) ---
  bool _isLoading = false;
  UserModel? _user;

  List<Map<String, dynamic>> _userPosts = [];


  /// --- Getters ---
  bool get isLoading => _isLoading;
  String get userName => _user?.username ?? 'Đang tải...';
  String get profileImageUrl => _user?.profile ?? '';
  int get followerCount => _user?.followers.length ?? 0;
  int get followingCount => _user?.following.length ?? 0;
  UserModel? get user => _user;

  /// Khởi tạo: Tự động tải dữ liệu khi ViewModel được tạo
  ProfileViewModel() {
    ProfileData();
  }

  /// --- Logic tải Dữ liệu ---
  Future<void> ProfileData() async {
    if (_auth.currentUser == null) return;
    _setLoading(true);

    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _user = UserModel.fromMap(uid, userDoc.data()!);}


      /// 2. Lấy Bài đăng của Người dùng
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('ownerID', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      _userPosts = postsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Lỗi khi tải dữ liệu trang cá nhân: $e');
      /// Có thể hiển thị một thông báo lỗi trên UI
    } finally {
      _setLoading(false);
    }
  }

  /// --- Hàm hỗ trợ ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  /// --- Stream realtime Posts ---
  Stream<List<Map<String, dynamic>>> getUserPostsStream() {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection('posts')
        .where('ownerID', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }
}