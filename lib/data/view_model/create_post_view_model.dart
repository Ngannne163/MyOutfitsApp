import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_servise/firestore.dart';
import '../firebase_servise/storage.dart';

class CreatePostViewModel extends ChangeNotifier {
  final StorageMethod _storage = StorageMethod();
  final Firebase_Firestore _firestore = Firebase_Firestore();

  /// --- State: Trạng thái và Dữ liệu ---
  bool _isLoading = false;
  List<File> _selectedImages = [];
  String _description = '';
  String _error = '';

  /// Tags cấu trúc
  List<String> _styleTags = [];
  List<String> _placeTags = [];
  List<String> _seasonTags = [];
  List<String> _customHashtags = [];

  /// --- Getters ---
  bool get isLoading => _isLoading;
  List<File> get selectedImages => _selectedImages;
  String get description => _description;
  List<String> get styleTags => _styleTags;
  List<String> get placeTags => _placeTags;
  List<String> get seasonTags => _seasonTags;
  List<String> get customHashtags => _customHashtags;
  String get error => _error;

  /// --- Logic quản lý Ảnh (Screen 1: ĐĂNG ẢNH) ---

  void addImage(File image) {
    _selectedImages.add(image);
    notifyListeners();
  }

  void removeImage(File image) {
    _selectedImages.remove(image);
    notifyListeners();
  }

  /// --- Logic quản lý Caption và Tags (Screen 2: ĐĂNG CAPTION) ---

  void setDescription(String desc) {
    _description = desc;
    notifyListeners();
  }

  void addCustomHashtag(String hashtag) {
    final cleanHashtag = hashtag.startsWith('#')
        ? hashtag.substring(1).toLowerCase()
        : hashtag.toLowerCase();
    if (cleanHashtag.isNotEmpty && !_customHashtags.contains(cleanHashtag)) {
      _customHashtags.add(cleanHashtag);
      notifyListeners();
    }
  }

  void removeCustomHashtag(String hashtag) {
    _customHashtags.remove(hashtag);
    notifyListeners();
  }

  void toggleStyleTag(String tag) {
    if (_styleTags.contains(tag)) {
      _styleTags.remove(tag);
    } else {
      _styleTags.add(tag);
    }
    notifyListeners();
  }

  void togglePlaceTag(String tag) {
    if (_placeTags.contains(tag)) {
      _placeTags.remove(tag);
    } else {
      _placeTags.add(tag);
    }
    notifyListeners();
  }

  void toggleSeasonTag(String tag) {
    if (_seasonTags.contains(tag)) {
      _seasonTags.remove(tag);
    } else {
      _seasonTags.add(tag);
    }
    notifyListeners();
  }

  /// --- Hàm Chính: Thực hiện Đăng bài ---

  Future<String> createPost() async {
    if (_selectedImages.isEmpty) {
      _error = 'Vui lòng chọn ít nhất một ảnh.';
      notifyListeners();
      return 'Vui lòng chọn ít nhất một ảnh.'; /// Trả về thông báo lỗi
    }
    _setLoading(true);
    _error = ''; /// Reset lỗi trước khi bắt đầu

    String newPostId = FirebaseFirestore.instance.collection('posts').doc().id;

    try {
      List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final url = await _storage.uploadPostImage(image, newPostId);
        imageUrls.add(url);
      }

      await _firestore.createPost(
        imageURLs: imageUrls,
        description: _description,
        styleTags: _styleTags,
        placeTags: _placeTags,
        seasonTags: _seasonTags,
        customHashtags: _customHashtags,
      );

      _resetViewModel();
      return 'Đăng bài thành công'; /// Trả về thành công
    } catch (e) {
      print('Lỗi khi đăng bài: $e');
      _error = 'Không thể đăng bài. Vui lòng thử lại.';
      notifyListeners();
      return _error; /// Trả về lỗi
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _resetViewModel() {
    _selectedImages = [];
    _description = '';
    _styleTags = [];
    _placeTags = [];
    _seasonTags = [];
    _customHashtags = [];
    _error = '';
    notifyListeners();
  }
}
