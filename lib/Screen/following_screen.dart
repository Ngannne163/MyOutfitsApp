import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_outfits/data/model/user_model.dart';
import 'package:provider/provider.dart';
import '../data/view_model/following_view_model.dart';
import '../routes/app_routes.dart';
import '../util/postcard_widget.dart';


class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {

      Provider.of<FollowingViewModel>(context, listen: false).loadFollowingData();
    });
  }

  Widget _buildFollowingAvatar(List<UserModel> users, String? selectedUserId, FollowingViewModel viewModel) {
    // Thêm một UserModel giả định cho mục "Tất cả" (hoặc "Your Story")
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final List<UserModel> allUsers = [
      UserModel(
        uid: currentUser?.uid ?? 'all',
        username: 'Tất cả',
        profile: 'https://firebasestorage.googleapis.com/v0/b/myoutfits-937e9.firebasestorage.app/o/person.png?alt=media&token=204a0a4f-ecc3-4599-b9a9-0edda28ca308', // Hoặc ảnh đại diện của user hiện tại
        styles: [],
        followers: [], following: [], // Không cần thiết
      ),
      ...users
    ];

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allUsers.length,
        itemBuilder: (context, index) {
          final user = allUsers[index];
          final isSelected = selectedUserId == user.uid || (index == 0 && selectedUserId == null);

          // 🟢 Độ mờ (Opacity)
          final opacity = isSelected ? 1.0 : 0.5;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Opacity(
              opacity: opacity, // Áp dụng độ mờ
              child: GestureDetector(
                onTap: () {
                  // Gọi hàm lọc với userId của user được chọn
                  viewModel.selectUserAndFilter(user.uid);
                },
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.pink.shade300 : Colors.grey, // Border đậm khi được chọn
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: user.profile != null && user.profile!.isNotEmpty
                            ? NetworkImage(user.profile!) as ImageProvider
                            : const AssetImage('assets/default_avatar.png'),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Username
                    Text(
                      user.username.length > 8 ? '${user.username.substring(0, 7)}...' : user.username,
                      style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowingViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.following.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (viewModel.errorMessage.isNotEmpty) {
          return Center(
              child: Text(viewModel.errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16)));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Avatars (Người đang theo dõi)
              _buildFollowingAvatar(viewModel.followingUsers, viewModel.selectedUserId, viewModel),

              // 2. Divider nhẹ
              const Divider(height: 1, thickness: 0.5, color: Colors.grey),

              // 3. Phần Bài viết (GridView)
              viewModel.following.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Không có bài viết nào phù hợp.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: viewModel.following.length,
                itemBuilder: (context, index) {
                  final outfit = viewModel.following[index];

                  List<String> imageUrls = [];
                  final rawImageUrls = outfit['imageURLs'];
                  if (rawImageUrls is List) {
                    imageUrls = rawImageUrls.whereType<String>().toList();
                  }

                  return PostCardWidget(
                    imageUrls: imageUrls,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.outfits,
                        arguments: outfit,
                      );
                    },
                  );
                },
              ),
              if (viewModel.isLoading)
                const LinearProgressIndicator(minHeight: 2)
            ],
          ),
        );
      },
    );
  }

}