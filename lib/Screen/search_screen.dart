import 'package:flutter/material.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:provider/provider.dart';

import '../data/view_model/search_view_model.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: Consumer<SearchViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            body: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: (query) {
                      viewModel.searchGlobal(query);
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm Outfits, Tags, Mô tả...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: viewModel.currentQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                viewModel.clearSearch();
                                FocusScope.of(
                                  context,
                                ).unfocus(); /// Đóng bàn phím
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),

                /// Hiển thị trạng thái và kết quả
                Expanded(child: _buildBody(viewModel)),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildBody(SearchViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.currentQuery.isEmpty) {
      return const Center(child: Text('Bắt đầu gõ để tìm kiếm'));
    }

    if (viewModel.searchResults.isEmpty) {
      return Center(
        child: Text('Không tìm thấy kết quả cho "${viewModel.currentQuery}"'),
      );
    }

    /// Hiển thị danh sách kết quả
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: viewModel.searchResults.length,
      itemBuilder: (context, index) {
        final item = viewModel.searchResults[index];
        final type = item['type'] as String;

        return SearchGridCard(item: item, type: type);
      },
    );
  }
}

/// Widget hiển thị kết quả tìm kiếm (Post hoặc Outfit)
class SearchGridCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;

  const SearchGridCard({super.key, required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    final imageURLs = item['imageURLs'] as List? ?? [];
    final imageUrl = type == 'post'
        ? (imageURLs.isNotEmpty ? imageURLs.first : null)
        : item['imageURL'] as String?;

    final color = type == 'post' ? Colors.green.shade600 : Colors.blue.shade600;
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.outfits, arguments: item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        /// Hiển thị ảnh
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(context, color, type),
                )
              : _buildPlaceholder(context, color, type),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, Color color, String type) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'post' ? Icons.article_outlined : Icons.checkroom_outlined,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              type == 'post' ? 'Bài đăng' : 'Outfit',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
