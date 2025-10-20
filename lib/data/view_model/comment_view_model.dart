import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_outfits/data/firebase_servise/firestore.dart';
import 'package:my_outfits/data/model/comment_model.dart';
import 'package:my_outfits/data/model/user_model.dart';

class CommentViewModel extends ChangeNotifier {
  final Firebase_Firestore _firestoreService = Firebase_Firestore();
  final String _postId;

  Stream<List<CommentModel>>? _commentsStream;
  List<CommentModel> _comments = [];
  bool _isPosting = false;
  String? _errorMessage;
  String? _currentUserProfileUrl;

  List<CommentModel> get comments => _comments;
  bool get isPosting => _isPosting;
  String? get errorMessage => _errorMessage;
  String? get currentUserProfileUrl => _currentUserProfileUrl;

  CommentViewModel({required String postId, String? initialUserAvatarUrl}) : _postId = postId {
    if (initialUserAvatarUrl != null) {
      _currentUserProfileUrl = initialUserAvatarUrl;
    }
    _startListeningToComments();
    _loadCurrentUserProfile();
  }

  void _startListeningToComments() {
    _commentsStream = _firestoreService.getCommentsStream(_postId);
    _commentsStream!.listen((newComments) {
      _comments = newComments;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = 'Lỗi tải bình luận: ${error.toString()}';
      notifyListeners();
    });
  }

  Future<void> _loadCurrentUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      UserModel? user = await _firestoreService.getUserInfo(currentUser.uid);
      if (user != null) {
        _currentUserProfileUrl = user.profile;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading current user profile URL: $e');
    }
  }

  Future<void> postComment(String content) async {
    if (content.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _errorMessage = "Vui lòng đăng nhập để bình luận.";
      notifyListeners();
      return;
    }

    _isPosting = true;
    notifyListeners();

    try {
      /// Lấy thông tin user hiện tại (username, avatar)
      UserModel? user = await _firestoreService.getUserInfo(currentUser.uid);
      if (user == null) {
        throw Exception("Không tìm thấy thông tin người dùng.");
      }

      if (_currentUserProfileUrl != user.profile) {
        _currentUserProfileUrl = user.profile;
      }

      ///Gọi hàm post lên Firestore
      await _firestoreService.postComment(
        postId: _postId,
        content: content,
        currentUserId: currentUser.uid,
        username: user.username,
        userProfileUrl: user.profile,
      );

    } catch (e) {
      _errorMessage = 'Lỗi khi gửi bình luận: ${e.toString()}';
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _commentsStream?.listen((_) {}).cancel();
    super.dispose();
  }
}