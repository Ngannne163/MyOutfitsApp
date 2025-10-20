import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_outfits/data/firebase_servise/firestore.dart';

import '../model/user_model.dart';

class FollowingViewModel extends ChangeNotifier {
  final Firebase_Firestore _firestoreService = Firebase_Firestore();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<UserModel> _followingUsers = [];
  List<Map<String, dynamic>> _following = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String? _selectedUserId;

  List<UserModel> get followingUsers => _followingUsers;
  List<Map<String, dynamic>> get following => _following;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get selectedUserId => _selectedUserId;

  Future<void> loadFollowingData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (currentUser == null) throw Exception("Người dùng chưa đăng nhập.");
      DocumentSnapshot userDoc = await _firestoreService.getUserData(currentUser!.uid);
      List<String> followingIds = List<String>.from(userDoc['following'] ?? []);

      if (followingIds.isEmpty) {
        _followingUsers =[];
        _following = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      List<String> limitedFollowingIds = followingIds.sublist(0, followingIds.length > 10 ? 10 : followingIds.length);

      List<UserModel> users = [];
      for (var id in limitedFollowingIds) {
        UserModel? user = await _firestoreService.getUserInfo(id);
        if (user != null) {
          users.add(user);
        }
      }
      _followingUsers = users;

      await _fetchOutfits(followingIds);

    } on Exception catch (e) {
      _errorMessage = 'Lỗi tải outfits từ người đang theo dõi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchOutfits(List<String> userIdsToFetch) async {
    try {
      if (userIdsToFetch.isEmpty) {
        _following = [];
        return;
      }

      List<String> limitedUserIds = userIdsToFetch.sublist(0, userIdsToFetch.length > 10 ? 10 : userIdsToFetch.length);

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('ownerID', whereIn: limitedUserIds)
          .orderBy('timestamp', descending: true) // Thêm order by
          .get();

      _following = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      // Xử lý lỗi tải outfits
      print('Lỗi khi tải outfits: $e');
    }
  }

  Future<void> selectUserAndFilter(String userId) async {
    final isSelectAll = userId == (currentUser?.uid ?? 'all');


    if (_selectedUserId == userId || isSelectAll) {
      _selectedUserId = null;
    } else {
      _selectedUserId = userId;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_selectedUserId == null) {
        // 1. Tải lại TẤT CẢ outfits (cần lấy lại danh sách ID ban đầu)
        DocumentSnapshot userDoc = await _firestoreService.getUserData(currentUser!.uid);
        List<String> allFollowingIds = List<String>.from(userDoc['following'] ?? []);
        await _fetchOutfits(allFollowingIds);
      } else {
        // 2. Tải outfits chỉ của người dùng được chọn
        await _fetchOutfits([_selectedUserId!]);
      }
    } catch (e) {
      _errorMessage = 'Lỗi lọc bài viết: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}