import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../data/view_model/edit_post_view_model.dart'; // SỬ DỤNG VIEW MODEL MỚI

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _hashtagController = TextEditingController();

  static const List<String> availableStyleTags = [
    'casual',
    'streetwear',
    'vintage',
    'retro',
    'classic',
    'bohemian',
    'business',
    'sporty',
    'y2k',
    'traditional',
    'romantic',
    'unisex',
    'minimalist',
  ];
  static const List<String> availablePlaceTags = [
    'cafe',
    'sea',
    'campus',
    'date',
    'office',
    'travel',
    'wedding',
    'daily',
    'vacation',
  ];
  static const List<String> availableSeasonTags = [
    'summer',
    'autumn',
    'spring',
    'winter',
  ];

  @override
  void dispose() {
    _hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditPostViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: _buildAppBar(context, viewModel),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 90.0,
                ),
                child: Column(
                  children: [
                    _buildImageSelectionContent(viewModel),
                    const SizedBox(height: 20),
                    _buildCaptionAndTagsContent(context, viewModel),
                  ],
                ),
              ),
              _buildSaveButton(context, viewModel),
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      },
    );
  }

  /// --- Widget AppBar ---
  AppBar _buildAppBar(BuildContext context, EditPostViewModel viewModel) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context), // Đóng màn hình
      ),
      title: const Text(
        'Chỉnh sửa bài viết', // Đổi tên
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: viewModel.isLoading
              ? null
              : () {
            Navigator.pop(context);
                },
          child: Text(
            'Hủy bỏ',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// --- Widget Chỉnh sửa Ảnh (Tái cấu trúc từ Bước 1) ---
  Widget _buildImageSelectionContent(EditPostViewModel viewModel) {
    final allImages = [...viewModel.existingImageURLs, ...viewModel.newImages];

    Future<void> pickNewImage() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        viewModel.addNewImage(File(image.path));
      }
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: allImages.length + 1,
          itemBuilder: (context, index) {
            if (index == allImages.length) {
              // Nút Thêm Ảnh
              return GestureDetector(
                onTap: pickNewImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.grey),
                ),
              );
            }

            final item = allImages[index];
            final isExisting =
                index < viewModel.existingImageURLs.length;

            ImageProvider imageProvider;
            if (isExisting) {
              imageProvider = NetworkImage(item as String);
            } else {
              imageProvider = FileImage(item as File);
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(image: imageProvider, fit: BoxFit.cover),
                ),
                // Nút Xóa
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      if (isExisting) {
                        viewModel.removeExistingImage(item as String);
                      } else {
                        viewModel.removeNewImage(item as File);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCaptionAndTagsContent(
    BuildContext context,
    EditPostViewModel viewModel,
  ) {
    void addTag() {
      if (_hashtagController.text.isNotEmpty) {
        viewModel.addCustomHashtag(_hashtagController.text);
        _hashtagController.clear();
      }
    }

    // 🟢 Tái sử dụng cấu trúc
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🟢 TextField: Thêm initialValue để hiển thị caption cũ
        TextField(
          controller: TextEditingController(
            text: viewModel.description,
          ), // Dùng Controller để set initialValue
          onChanged: viewModel.setDescription,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Thêm chú thích...",
            border: InputBorder.none,
          ),
          keyboardType: TextInputType.multiline,
        ),

        const Divider(),

        /// 2. Trường nhập Hashtag tùy chỉnh (Vẫn giữ)
        TextField(
          controller: _hashtagController,
          decoration: InputDecoration(
            hintText: "#Thêm hastage",
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: addTag,
            ),
          ),
          onSubmitted: (_) => addTag(),
        ),

        /// 3. Danh sách Hashtag đã chọn (Vẫn giữ)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: viewModel.customHashtags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                onDeleted: () => viewModel.removeCustomHashtag(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
              );
            }).toList(),
          ),
        ),

        const Divider(),

        /// 4. Vùng chọn Tags Cấu trúc (Style, Place, Season) - Vẫn giữ
        const Text(
          "Tags Phong cách:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availableStyleTags.map((tag) {
            final isSelected = viewModel.styleTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) => viewModel.toggleStyleTag(tag),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        ///places tag
        const Text(
          "Tags places:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availablePlaceTags.map((tag) {
            final isSelected = viewModel.placeTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) => viewModel.togglePlaceTag(tag),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        /// Season Tags
        const Text("Tags Mùa:", style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availableSeasonTags.map((tag) {
            final isSelected = viewModel.seasonTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) => viewModel.toggleSeasonTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, EditPostViewModel viewModel) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
                    final result = await viewModel.updatePost(context);
                    if (mounted && result != "Cập nhật thành công") {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(result)));
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              viewModel.isLoading ? 'Đang lưu...' : 'LƯU CHỈNH SỬA',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
