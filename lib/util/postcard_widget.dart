import 'package:flutter/material.dart';

class PostCardWidget extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback? onTap;

  const PostCardWidget({super.key, required this.imageUrls, this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstImage = imageUrls.isNotEmpty ? imageUrls.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: Stack(
          children: [
            /// Ảnh chính
            Positioned.fill(
              child: firstImage != null && firstImage.isNotEmpty
                  ? Image.network(
                firstImage,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator());
                },
              )
                  : const Center(child: Icon(Icons.image_not_supported)),
            ),

            /// Icon "nhiều ảnh" (Instagram style)
            if (imageUrls.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.collections,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
