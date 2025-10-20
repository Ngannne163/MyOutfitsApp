import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:my_outfits/data/view_model/create_post_view_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  /// 1. Quản lý trạng thái bước (Step State Management)
  bool _isCaptionStep = false;
  final ImagePicker _picker = ImagePicker();

  /// Controller cho input Hashtag (chỉ dùng trong màn hình này)
  final TextEditingController _hashtagController = TextEditingController();

  /// --- Logic Ảnh ---
  Future<void> _pickImage(CreatePostViewModel viewModel) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      viewModel.addImage(File(image.path));
    }
  }

  /// --- Logic Chuyển Bước ---
  void _nextStep() {
    setState(() {
      _isCaptionStep = true;
    });
  }

  void _previousStep() {
    setState(() {
      _isCaptionStep = false;
    });
  }

  /// ĐỊNH NGHĨA STATIC TAGS (Yêu cầu 4)
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
  Widget build(BuildContext context) {
    return Consumer<CreatePostViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: _buildAppBar(context, viewModel),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (!_isCaptionStep) _buildImageSelectionContent(viewModel),
                    if (_isCaptionStep)
                      _buildCaptionAndTagsContent(context, viewModel),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// --- Widget AppBar (Thay đổi theo Bước) ---
  AppBar _buildAppBar(BuildContext context, CreatePostViewModel viewModel) {
    final bool canProceed = viewModel.selectedImages.isNotEmpty;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(_isCaptionStep ? Icons.arrow_back : Icons.close),
        onPressed: () {
          if (_isCaptionStep) {
            _previousStep();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: const Text(
        'Bài viết mới',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (!_isCaptionStep && canProceed) {
              _nextStep();
            } else if (_isCaptionStep && !viewModel.isLoading) {
              final result = await viewModel.createPost();
              if (result == "Đăng bài thành công") {
                if (mounted) Navigator.pop(context);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result)));
                }
              }
            }
          },
          child: Text(
            _isCaptionStep ? 'Chia sẻ' : 'Tiếp',
            style: TextStyle(
              color: (_isCaptionStep || canProceed)
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// --- Widget Bước 1: ĐĂNG ẢNH ---
  Widget _buildImageSelectionContent(CreatePostViewModel viewModel) {
    /// Tái sử dụng logic hiển thị ảnh lớn và Grid ảnh nhỏ
    return Column(
      children: [
        /// Vùng hiển thị ảnh lớn
        Container(
          height: MediaQuery.of(context).size.height * 0.4,
          color: Colors.grey[200],
          child: viewModel.selectedImages.isNotEmpty
              ? Image.file(viewModel.selectedImages.first, fit: BoxFit.cover)
              : const Center(child: Text('Chọn ảnh để bắt đầu')),
        ),
        const SizedBox(height: 10),

        /// Vùng hiển thị Grid ảnh nhỏ
        GridView.builder(
          shrinkWrap: true,

          /// Quan trọng: GridView trong Column
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: viewModel.selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: () => _pickImage(viewModel),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.grey),
                ),
              );
            }
            final File imageFile = viewModel.selectedImages[index - 1];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => viewModel.removeImage(imageFile),
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

  /// --- Widget Bước 2: ĐĂNG CAPTION và Tags ---
  Widget _buildCaptionAndTagsContent(
    BuildContext context,
    CreatePostViewModel viewModel,
  ) {
    void addTag() {
      if (_hashtagController.text.isNotEmpty) {
        viewModel.addCustomHashtag(_hashtagController.text);
        _hashtagController.clear();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: viewModel.setDescription,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Thêm chú thích...",
            border: InputBorder.none,
          ),
          keyboardType: TextInputType.multiline,
        ),

        const Divider(),

        /// 2. Trường nhập Hashtag tùy chỉnh
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

        /// 3. Danh sách Hashtag đã chọn
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

        /// 4. Vùng chọn Tags Cấu trúc (Style, Place, Season)
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
}
