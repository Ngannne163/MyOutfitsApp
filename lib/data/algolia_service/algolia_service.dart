import 'package:algolia_client_search/algolia_client_search.dart' as algolia;
import 'package:flutter/foundation.dart';

class AlgoliaSearchService {
  static const String ALGOLIA_APP_ID = 'RP42OZFM22';
  static const String ALGOLIA_SEARCH_KEY = '687c565ffff66a964be19b4e23a7b50d';

  final algolia.SearchClient _client = algolia.SearchClient(appId: ALGOLIA_APP_ID, apiKey: ALGOLIA_SEARCH_KEY);

  Future<List<Map<String, dynamic>>> searchGlobal(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final postsResponse = await _client.searchSingleIndex(
        indexName: 'posts_index',
        searchParams: algolia.SearchParamsObject(query: q, hitsPerPage: 10),
      );

      final outfitsResponse = await _client.searchSingleIndex(
        indexName: 'outfits_index',
        searchParams: algolia.SearchParamsObject(query: q, hitsPerPage: 5),
      );

      final combined = <Map<String, dynamic>>[];

      // posts
      for (final hit in postsResponse.hits) {
        final m = Map<String, dynamic>.from(hit);
        m['type'] = 'post';
        combined.add(m);
      }

      // outfits
      for (final hit in outfitsResponse.hits) {
        final m = Map<String, dynamic>.from(hit);
        m['type'] = 'outfit';
        combined.add(m);
      }


      return combined;
    } catch (e, st) {
      if (kDebugMode) {
        print('Algolia search error: $e\n$st');
      }
      return [];
    }
  }

  void dispose() {
    _client.dispose();
  }
}