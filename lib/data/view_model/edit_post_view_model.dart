import 'dart:io';
import 'package:flutter/material.dart';
import '../firebase_servise/firestore.dart';
import '../firebase_servise/storage.dart';


class EditPostViewModel extends ChangeNotifier {
  final StorageMethod _storage = StorageMethod();
  final Firebase_Firestore _firestore = Firebase_Firestore();

  // Dữ liệu bài viết ban đầu
  final Map<String, dynamic> initialPost;

  /// --- State: Trạng thái và Dữ liệu ---
  bool _isLoading = false;

  String _postId = '';
  List<String> _imageURLs = [];
  List<File> _newImages = [];

  String _description = '';

  // Các tags cấu trúc
  List<String> _styleTags = [];
  List<String> _placeTags = [];
  List<String> _seasonTags = [];
  List<String> _customHashtags = [];


  /// --- Getters ---
  bool get isLoading => _isLoading;
  String get postId => _postId;
  List<String> get existingImageURLs => _imageURLs;
  List<File> get newImages => _newImages;
  String get description => _description;
  List<String> get styleTags => _styleTags;
  List<String> get placeTags => _placeTags;
  List<String> get seasonTags => _seasonTags;
  List<String> get customHashtags => _customHashtags;


  EditPostViewModel(this.initialPost) {
    _postId = initialPost['postId'] ?? initialPost['outfitId'] ?? '';

    /// Tải ảnh cũ
    if (initialPost['imageURLs'] is List) {
      _imageURLs = List<String>.from(initialPost['imageURLs']);
    } else if (initialPost['imageURLs'] is String && initialPost['imageURLs'].isNotEmpty) {
      /// Trường hợp post cũ chỉ lưu 1 ảnh dưới dạng String
      _imageURLs = [initialPost['imageURLs']];
    }

    /// Tải các trường khác
    _description = initialPost['description'] ?? '';
    _styleTags = List<String>.from(initialPost['styleTags'] ?? []);
    _placeTags = List<String>.from(initialPost['placeTags'] ?? []);
    _seasonTags = List<String>.from(initialPost['seasonTags'] ?? []);
    _customHashtags = List<String>.from(initialPost['customHashtags'] ?? []);
  }


  /// Thêm ảnh mới
  void addNewImage(File image) {
    _newImages.add(image); /// Thêm vào list ảnh MỚI
    notifyListeners();
  }

  /// Xóa ảnh mới:
  void removeNewImage(File image) {
    _newImages.remove(image);
    notifyListeners();
  }

  Future<void> removeExistingImage(String imageUrl) async {
    _setLoading(true);
    try {
      await _storage.deleteSingleImage(imageUrl);
      _imageURLs.remove(imageUrl);
      notifyListeners();
    } catch (e) {
      print('Lỗi khi xóa ảnh đã có: $e');
    } finally {
      _setLoading(false);
    }
  }


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

  /// --- Hàm Chính: CẬP NHẬT Bài viết ---

  Future<String> updatePost(BuildContext context) async {
    if (_imageURLs.isEmpty && _newImages.isEmpty) {
      return 'Bài viết phải có ít nhất một ảnh.';
    }
    _setLoading(true);

    List<String> finalImageURLs = List.from(_imageURLs);
    try {
      /// Upload các ảnh mới lên Firebase Storage
      for (final image in _newImages) {
        // Tái sử dụng hàm uploadPostImage của Storage
        final url = await _storage.uploadPostImage(image, _postId);
        finalImageURLs.add(url);
      }

      ///Cập nhật Firestore (Gọi hàm updatePost đã thêm vào Firestore Service)
      await _firestore.updatePost(
        postId: _postId,
        newImageURLs: finalImageURLs,
        description: _description,
        styleTags: _styleTags,
        placeTags: _placeTags,
        seasonTags: _seasonTags,
        customHashtags: _customHashtags,
      );

      /// Cập nhật thành công
      Navigator.pop(context, true);
      return 'Cập nhật thành công';

    } catch (e) {
      print('Lỗi khi cập nhật bài viết: $e');
      return 'Không thể cập nhật bài viết. Vui lòng thử lại.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}