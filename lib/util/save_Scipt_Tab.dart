import 'package:flutter/material.dart';
import 'package:my_outfits/util/postcard_widget.dart';
import '../routes/app_routes.dart';

class SavedGridTab extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() fetchData;
  final String emptyMessage;
  final IconData emptyIcon;

  const SavedGridTab({
    required this.fetchData,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  State<SavedGridTab> createState() => SavedGridTabState();
}

class SavedGridTabState extends State<SavedGridTab> {
  late Future<List<Map<String, dynamic>>> _futureOutfits;

  @override
  void initState() {
    super.initState();
    _futureOutfits = widget.fetchData();
  }

  void _refreshData() {
    setState(() {
      _futureOutfits = widget.fetchData();
    });
  }

  @override
  void didUpdateWidget(covariant SavedGridTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fetchData != widget.fetchData) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            await _futureOutfits;
          },

          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureOutfits,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
              }

              final outfits = snapshot.data ?? [];

              if (outfits.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height -
                        kToolbarHeight,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.emptyIcon,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.emptyMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Hiển thị Lưới bài viết
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  final post = outfits[index];

                  List<String> imageUrls = [];
                  if (post['imageURLs'] is List) {
                    imageUrls = (post['imageURLs'] as List)
                        .whereType<String>()
                        .toList();
                  } else if (post['imageURL'] is String &&
                      post['imageURL'].isNotEmpty) {
                    imageUrls.add(post['imageURL']);
                  }

                  debugPrint('--- [SavedGridTab] Post ID: ${post['postId']}');
                  debugPrint('Image URLs found: ${imageUrls.length} urls');
                  if (imageUrls.isEmpty) {
                    debugPrint(
                      '🚨 ERROR: ImageURLs field content: ${post['imageURLs']}',
                    );
                    debugPrint(
                      '🚨 ERROR: ImageURL field content: ${post['imageURL']}',
                    );
                  }

                  return PostCardWidget(
                    imageUrls: imageUrls,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.outfits,
                        arguments: post,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
