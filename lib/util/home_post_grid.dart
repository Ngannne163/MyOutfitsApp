import 'package:flutter/material.dart';
import 'package:my_outfits/data/view_model/home_view_model.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:my_outfits/util/postcard_widget.dart';
import 'package:provider/provider.dart';

class HomePostGrid extends StatelessWidget {
  const HomePostGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    Future<void> _onRefresh() async {
      await viewModel.loadForYou(forceRefresh: true);
    }

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error.isNotEmpty) {
      return Center(
        child: Text(
          viewModel.error,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    if (viewModel.forYou.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            SizedBox(height: 200),
            Center(
              child: Text(
                'Không có outfit nào để hiển thị.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.75,
        ),
        itemCount: viewModel.forYou.length,
        itemBuilder: (context, index) {
          final post = viewModel.forYou[index];

          if (post.isEmpty || post['postId'] == null) {
            debugPrint(
              'Bỏ qua post Index $index: Dữ liệu trống/thiếu postId.',
            );
            return Container();
          }

          List<String> imageUrls = [];
          if (post['imageURL'] is String && post['imageURL'].isNotEmpty) {
            imageUrls.add(post['imageURL']);
          } else if (post['imageURLs'] is List) {
            imageUrls = (post['imageURLs'] as List)
                .whereType<String>()
                .toList();
          }

          return PostCardWidget(
            imageUrls: imageUrls,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.outfits, arguments: post);
            },
          );
        },
      ),
    );
  }
}
