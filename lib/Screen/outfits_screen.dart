import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_outfits/data/view_model/outfits_view_model.dart';
import 'package:provider/provider.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OutfitsScreen extends StatefulWidget {
  final Map<String, dynamic> outfitData;

  const OutfitsScreen({super.key, required this.outfitData});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  String? _getFirstImage(Map<String, dynamic> outfit) {
    final dynamic single = outfit['imageURL'];
    if (single != null && single is String && single.isNotEmpty) return single;
    final dynamic list = outfit['imageURLs'] ?? outfit['imageURLs'];
    if (list != null && list is List && list.isNotEmpty) {
      final first = list[0];
      if (first is String && first.isNotEmpty) return first;
      return first?.toString();
    }

    final dynamic alt = outfit['imageURLs'] ?? outfit['imageURL'];
    if (alt != null && alt is List && alt.isNotEmpty) return alt[0] as String?;
    return null;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
    }
    if (timestamp is String) {
      return timestamp;
    }
    return 'Ngày không rõ';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OutfitsViewModel(widget.outfitData),
      child: Consumer<OutfitsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Chi tiết bài viết',
                style: TextStyle(color: Colors.black),
              ),
              centerTitle: true,
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.isDeleted
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.delete_forever,
                          size: 80,
                          color: Colors.black,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Bài viết đã bị xóa",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMainPost(
                          context,
                          viewModel.currentOutfit,
                          viewModel,
                        ),
                        _buildInteractionBar(context, viewModel),
                        _buildDescriptionAndTags(viewModel),
                        _buildSectionHeader(
                          'Bài viết khác của ${viewModel.creatorUser?.username ?? 'người tạo'}',
                        ),
                        _buildOutfitGrid(
                          context,
                          viewModel.otherUserOutfits,
                          viewModel,
                        ),
                        _buildSectionHeader('Phong cách tương tự'),
                        _buildOutfitGrid(
                          context,
                          viewModel.similarOutfits,
                          viewModel,
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildMainPost(
    BuildContext context,
    Map<String, dynamic> outfit,
    OutfitsViewModel viewModel,
  ) {
    List<String> imageUrls = [];
    final dynamic listImages = outfit['imageURLs'];
    if (listImages is List && listImages.isNotEmpty) {
      imageUrls = listImages.cast<String>();
    }
    else {
      final dynamic singleImage = outfit['imageURL'];
      if (singleImage is String && singleImage.isNotEmpty) {
        imageUrls.add(singleImage);
      }
    }
    final pageController = PageController();
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: viewModel.creatorUser?.profile != null
                ? NetworkImage(viewModel.creatorUser!.profile!)
                : null,
            child: viewModel.creatorUser?.profile == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(viewModel.creatorUser?.username ?? 'Người dùng'),
          subtitle: Text('${viewModel.creatorUser?.height?.toInt() ?? ''}cm'),

          ///Nếu bài viết không phải của user
          trailing: viewModel.creatorUser?.uid != viewModel.currentUserId
              ? TextButton(
                  onPressed: () {
                    viewModel.toggleFollow();
                  },
                  child: Text(
                    viewModel.isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                    style: TextStyle(
                      color: viewModel.isFollowing ? Colors.grey : Colors.blue,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: () => _showEditOptions(context, viewModel),
                  icon: const Icon(Icons.more_vert),
                ),
        ),
        if (imageUrls.isNotEmpty)
          Column(
            children: [
              SizedBox(
                height: 600,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              SmoothPageIndicator(
                controller: pageController,
                count: imageUrls.length,
                effect: const WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Colors.black,
                  dotColor: Colors.grey,
                ),
              ),
            ],
          )
        else
          Container(
            height: 400,
            color: Colors.grey[200],
            child: Center(
              child: Text(
                'Không tìm thấy ảnh',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractionBar(
    BuildContext context,
    OutfitsViewModel viewModel,
  ) {
    final timestamp = viewModel.currentOutfit['timestamp'];
    final dateString = _formatDate(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(viewModel.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: viewModel.isLiked ? Colors.red : Colors.grey,),
                onPressed: () {
                  viewModel.toggleLike();
                },
              ),
              Text('${viewModel.likesCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.mode_comment_outlined, color: Colors.grey,),
                onPressed: () {
                  viewModel.showCommentSheet(context);
                },
              ),
              Text('${viewModel.commentsCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon( viewModel.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: viewModel.isSaved ? Colors.black : Colors.grey,),
                onPressed: () {
                  viewModel.toggleSave();
                },
              ),
            ],
          ),
          Text(
            dateString,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionAndTags(OutfitsViewModel viewModel) {
    final outfit = viewModel.currentOutfit;
    final description = outfit['description'] ?? '';

    /// Gộp tất cả các loại tags lại (tags đã chọn và custom hashtags)
    final styleTags = List<String>.from(outfit['styleTags'] ?? []);
    final placeTags = List<String>.from(outfit['placeTags'] ?? []);
    final seasonTags = List<String>.from(outfit['seasonTags'] ?? []);
    final customHashtags = List<String>.from(outfit['customHashtags'] ?? []);

    final allTags = [
      ...styleTags,
      ...placeTags,
      ...seasonTags,
      ...customHashtags,
    ].map((tag) => '#$tag').join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${viewModel.creatorUser?.username ?? 'người tạo'}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.start,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),

          if (allTags.isNotEmpty)
            Text(
              allTags,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.left,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOutfitGrid(
    BuildContext context,
    List<Map<String, dynamic>> outfits,
    OutfitsViewModel viewModel,
  ) {
    if (outfits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Không tìm thấy bài viết nào.')),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: outfits.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final imageUrl = _getFirstImage(outfits[index]);
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.outfits,
              arguments: outfits[index],
            );
          },

          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _showCommentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        // TODO: Logic gửi bình luận
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditOptions(BuildContext context, OutfitsViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa bài viết'),
                onTap: () {
                  Navigator.pop(modalContext);
                  viewModel.editOutfit(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Xóa bài viết',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, viewModel);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, OutfitsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Xóa bài viết"),
          content: const Text("Bạn có chắc chắn muốn xóa bài viết này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await viewModel.deleteOutfit();
              },
              child: const Text("Xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
