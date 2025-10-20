import 'package:flutter/material.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../data/view_model/profile_view_model.dart';
import '../util/profile_post_grid.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        return RefreshIndicator(
          onRefresh: profileViewModel.ProfileData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(context, profileViewModel),
                const Divider(height: 1),

                _buildContentArea(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileViewModel viewModel) {
    Widget buildStatColumn(String label, int count) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            viewModel.isLoading ? '--' : count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      );
    }

    final currentProfileUrl = viewModel.profileImageUrl;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                backgroundImage: currentProfileUrl.isNotEmpty
                    ? NetworkImage(currentProfileUrl)
                    : null as ImageProvider?,
                child: currentProfileUrl.isEmpty && !viewModel.isLoading
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    buildStatColumn('follower', viewModel.followerCount),
                    buildStatColumn('following', viewModel.followingCount),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            viewModel.userName.isNotEmpty ? viewModel.userName : 'Đang tải...',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.editprofile);
                viewModel.ProfileData();
              },
              child: const Text('Chỉnh sửa trang cá nhân', style: TextStyle(color: Colors.black, fontSize: 16),),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: ProfilePostsGrid(),
    );
  }
}
