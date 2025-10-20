import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_outfits/data/firebase_servise/firestore.dart';
import 'package:my_outfits/data/model/user_model.dart';

class HomeViewModel extends ChangeNotifier {
  final Firebase_Firestore _firebaseFirestore = Firebase_Firestore();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  UserModel? _userData;
  List<Map<String, dynamic>> _forYou = [];
  bool _isLoading = true;
  bool _firstLoad = true;
  String _errorMessage = '';

  String? _selectQuickCategory;
  String? _genderFilter;
  double _minHeightFilter = 100;
  double _maxHeightFilter = 200;
  List<String> _placesFilter = [];
  List<String> _seasonFilter = [];
  List<String> _stylesFilter = [];

  ///Getter truy cập dữ liệu
  List<Map<String, dynamic>> get forYou => _forYou;
  bool get isLoading => _isLoading;
  bool get firstLoad => _firstLoad;
  String get error => _errorMessage;
  String? get selectQuickCategory => _selectQuickCategory;
  List<String> get placesFilter => _placesFilter;
  List<String> get seasonFilter => _seasonFilter;
  List<String> get stylesFilter => _stylesFilter;
  String? get userGender => _userData?.gender;
  String? get genderFilter => _genderFilter;
  double get minHeightFilter => _minHeightFilter;
  double get maxHeightFilter => _maxHeightFilter;

  HomeViewModel() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();
    try {

      final newUser = FirebaseAuth.instance.currentUser;
      if (newUser == null) throw Exception('Người dùng chưa đăng nhập.');
      DocumentSnapshot userDoc = await _firebaseFirestore.getUserData(
        currentUser!.uid,
      );
      if (userDoc.exists) {
        _userData = UserModel.fromMap(currentUser!.uid, userDoc.data() as Map<String, dynamic>);
        debugPrint('Giới tính người dùng: ${_userData?.gender}');
        await loadForYou();
      } else {
        throw Exception('Không tìm thấy dữ liệu người dùng.');
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải dữ liệu: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadForYou({ bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (_userData == null) {
        _errorMessage = 'Chưa có dữ liệu quiz';
        debugPrint('Lỗi: UserModel chưa được tải.');
        throw Exception('Quiz data is null');
      }

      if (forceRefresh) {
        _firstLoad = false;
        _forYou.clear();
      }

      List<Map<String, dynamic>> fetchOwnPosts = [];
      List<Map<String, dynamic>> fetchFollowingPosts = [];
      List<Map<String, dynamic>> fetchSuggestedPosts = [];
      List<Map<String, dynamic>> fetchOutfits = [];

      final idMapper = (QueryDocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['postId'] = doc.id;
        data['outfitId'] =
            doc.id;
        return data;
      };

      bool hasAdvancedFilters =
          _genderFilter != null ||
          _placesFilter.isNotEmpty ||
          _seasonFilter.isNotEmpty ||
          _stylesFilter.isNotEmpty ||
          (_minHeightFilter != 100 || _maxHeightFilter != 200);

      if (hasAdvancedFilters) {
        if (_genderFilter == 'man' || _genderFilter == null) {
          QuerySnapshot manSnapshot = await FirebaseFirestore.instance
              .collection('outfits')
              .doc('man')
              .collection('1')
              .get();
          fetchOutfits.addAll(manSnapshot.docs.map(idMapper));
        }

        if (_genderFilter == 'woman' || _genderFilter == null) {
          QuerySnapshot womanSnapshot = await FirebaseFirestore.instance
              .collection('outfits')
              .doc('woman')
              .collection('1')
              .get();
          fetchOutfits.addAll(womanSnapshot.docs.map(idMapper));
        }

        fetchOutfits = fetchOutfits.where((outfit) {
          bool placesMatch =
              _placesFilter.isEmpty ||
              (outfit['places'] is List &&
                  _placesFilter.any(
                    (place) => (outfit['places'] as List).contains(place),
                  ));
          bool seasonMatch =
              _seasonFilter.isEmpty ||
              (outfit['season'] is List &&
                  _seasonFilter.any(
                    (season) => (outfit['season'] as List).contains(season),
                  ));
          bool stylesMatch =
              _stylesFilter.isEmpty ||
              (outfit['categories'] is List &&
                  _stylesFilter.any(
                    (style) => (outfit['categories'] as List).contains(style),
                  ));
          return placesMatch && seasonMatch && stylesMatch;
        }).toList();
      } else {
        ///Lấy bài viết cá nhân (lần đầu)
        if (_firstLoad) {
          QuerySnapshot ownSnapshot = await FirebaseFirestore.instance
              .collection('posts')
              .where('ownerID', isEqualTo: currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();

          fetchOwnPosts = ownSnapshot.docs.map(idMapper).toList();
        }

        ///Lấy bài viết following
        List<dynamic> followingList = _userData!.following;
        if (followingList.isNotEmpty) {
          QuerySnapshot followingSnapshot = await FirebaseFirestore.instance
              .collection('posts')
              .where('ownerID', whereIn: followingList)
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();
          fetchFollowingPosts = followingSnapshot.docs.map(idMapper).toList();
        }

        ///Lấy suggestion post
        String? userGender = _userData!.gender;
        List<String> userStyle = List<String>.from(
          _userData!.styles,
        );
        debugPrint('--- Logic Gợi ý ---');
        debugPrint('Giới tính cho Gợi ý: $userGender');
        debugPrint('Styles cho Gợi ý: $userStyle');

        Query suggestedQuery = FirebaseFirestore.instance
            .collection('posts')
            .where(
              'timestamp',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 7)),
            )
            .orderBy('timestamp', descending: true);
        if (userGender != null) {
          suggestedQuery = suggestedQuery.where(
            'gender',
            isEqualTo: userGender,
          );
          debugPrint('Đã thêm WHERE: gender == $userGender');
        }
        if (userStyle.isNotEmpty) {
          suggestedQuery = suggestedQuery.where(
            'allTags',
            arrayContainsAny: userStyle,
          );
          debugPrint('Đã thêm WHERE: categories arrayContainsAny $userStyle');
        }
        QuerySnapshot suggestedSnapshot = await suggestedQuery.limit(20).get();
        fetchSuggestedPosts = suggestedSnapshot.docs.map(idMapper).toList();

        ///Lấy outfit từ Outfits
        debugPrint('--- Logic Outfits Mẫu ---');
        debugPrint('Giới tính cho Outfits: $userGender');

        if (userGender == 'man' || userGender == 'woman') {
          debugPrint('Truy vấn Outfit theo giới tính: outfits/$userGender/1');
          Query outfitQuery = FirebaseFirestore.instance
              .collection('outfits')
              .doc(userGender)
              .collection('1');
          if (userStyle.isNotEmpty) {
            outfitQuery = outfitQuery.where(
              'categories',
              arrayContainsAny: userStyle,
            );
          }
          QuerySnapshot snapshot = await outfitQuery.get();
          fetchOutfits = snapshot.docs.map(idMapper).toList();
        } else {
          debugPrint('Giới tính không xác định hoặc khác man/woman. Tải cả Nam và Nữ.');
          QuerySnapshot manSnapshot = await FirebaseFirestore.instance
              .collection('outfits')
              .doc('man')
              .collection('1')
              .get();
          QuerySnapshot womanSnapshot = await FirebaseFirestore.instance
              .collection('outfits')
              .doc('woman')
              .collection('1')
              .get();
          fetchOutfits = [
            ...manSnapshot.docs,
            ...womanSnapshot.docs,
          ].map(idMapper).toList();
        }
      }

      _forYou = [
        if (_firstLoad) ...fetchOwnPosts,
        ...fetchFollowingPosts,
        ...fetchSuggestedPosts,
        ...fetchOutfits,
      ];

      _firstLoad = false;

      print('Own posts: ${fetchOwnPosts.length}');
      print('Following posts: ${fetchFollowingPosts.length}');
      print('Suggested posts: ${fetchSuggestedPosts.length}');
      print('Outfits: ${fetchOutfits.length}');
      print('Tổng số bài viết trên Home: ${_forYou.length}');
    } on Exception catch (e) {
      _errorMessage = 'Lỗi tải Outfits: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters({
    String? gender,
    required List<String> places,
    required List<String> season,
    required List<String> styles,
    double? minHeight,
    double? maxHeight,
  }) {
    _genderFilter = gender;
    _placesFilter = places;
    _seasonFilter = season;
    _stylesFilter = styles;
    _minHeightFilter = minHeight ?? _minHeightFilter;
    _maxHeightFilter = maxHeight ?? _maxHeightFilter;
    loadForYou();
  }

  void updateFilter({
    String? gender,
    List<String>? places,
    List<String>? season,
    List<String>? styles,
    double? minHeight,
    double? maxHeight,
  }) {
    _genderFilter = gender;
    _seasonFilter = season ?? [];
    _placesFilter = places ?? [];
    _stylesFilter = styles ?? [];
    _minHeightFilter = minHeight ?? _minHeightFilter;
    _maxHeightFilter = maxHeight ?? _maxHeightFilter;
    loadForYou();
  }
}
