import 'package:flutter/material.dart';
import 'package:my_outfits/routes/app_routes.dart';

class OutfitGridItem extends StatelessWidget {
  final Map<String, dynamic> outfit;

  const OutfitGridItem({
    super.key,
    required this.outfit,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = List<String>.from(outfit['imageURLs'] ?? []);
    final String displayUrl = imageUrls.isNotEmpty ? imageUrls.first : '';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.outfits,
          arguments: outfit,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: displayUrl.isNotEmpty
              ? Image.network(
            displayUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(Icons.error_outline, color: Colors.red.shade400, size: 30),
              );
            },
          )
              : Center(
            child: Text(
              "Không có ảnh",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}