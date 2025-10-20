import 'package:flutter/foundation.dart';
import '../algolia_service/algolia_service.dart';

class SearchViewModel extends ChangeNotifier {
  final AlgoliaSearchService _service = AlgoliaSearchService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = '';

  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get currentQuery => _currentQuery;

  /// Thực hiện tìm kiếm toàn cầu
  Future<void> searchGlobal(String query) async {
    final q = query.trim();
    if (_currentQuery == q) return;

    _currentQuery = q;

    if (q.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final results = await _service.searchGlobal(q);
      _searchResults = results;
    } catch (e) {
      if (kDebugMode) {
        print('Error in SearchViewModel: $e');
      }
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    notifyListeners();
  }
}