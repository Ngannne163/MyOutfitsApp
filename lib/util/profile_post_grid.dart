import 'package:flutter/material.dart';
import 'package:my_outfits/data/view_model/profile_view_model.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:my_outfits/util/postcard_widget.dart';
import 'package:provider/provider.dart';

class ProfilePostsGrid extends StatelessWidget {
  const ProfilePostsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileViewModel>(context);

    /// Dùng StreamBuilder để nghe realtime posts
    return StreamBuilder<List<Map<String, dynamic>>>(
        stream: viewModel.getUserPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Hãy cùng chia sẻ phong cách của bạn nào!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'Hãy cùng chia sẻ phong cách của bạn nào!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1.0,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              List<String> imageUrls = [];
              if (post['imageURL'] is String && post['imageURL'].isNotEmpty) {
                imageUrls.add(post['imageURL']);
              } else if (post['imageURLs'] is List) {
                imageUrls =
                    (post['imageURLs'] as List).whereType<String>().toList();
              }

              return PostCardWidget(
                imageUrls: imageUrls,
                onTap: () {
                  Navigator.pushNamed(
                      context, AppRoutes.outfits, arguments: post);
                },
              );
            },
          );
        },
    );
  }
}