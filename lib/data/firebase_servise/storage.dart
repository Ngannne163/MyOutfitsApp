import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageMethod {
  final FirebaseAuth _auth= FirebaseAuth.instance;
  final FirebaseStorage _storage= FirebaseStorage.instance;

  Future<String> uploadImageToStorage(String name, File file)async{
    Reference ref =_storage.ref().child(_auth.currentUser!.uid);
    
    UploadTask uploadTask =ref.putFile(file);
    TaskSnapshot snapshot=await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadPostImage(File file, String postId) async {
    /// Tạo tên file duy nhất bằng timestamp
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    /// Sử dụng 'Posts' làm thư mục con cho ảnh bài đăng
    Reference ref = _storage
        .ref()
        .child('Posts')
        .child(_auth.currentUser!.uid)
        .child(postId)
        .child(fileName); /// Tên file duy nhất

    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot=await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> deleteOutfitImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      }
      print("🗑️ Đã xóa tất cả ảnh trong Storage.");
    } catch (e) {
      print("Cảnh báo: Lỗi khi xóa ảnh trong Storage, có thể thư mục không tồn tại: $e");
    }
  }

  Future<void> deleteSingleImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print("🗑️ Đã xóa ảnh đơn lẻ trong Storage: $imageUrl");
    } catch (e) {
      print("Cảnh báo: Lỗi khi xóa ảnh đơn lẻ: $e");
    }
  }
}