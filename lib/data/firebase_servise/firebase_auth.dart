import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_outfits/data/firebase_servise/firestore.dart';
import 'package:my_outfits/data/firebase_servise/storage.dart';
import 'package:my_outfits/util/exception.dart';

class Authentication {
  FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn.instance;


  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Sau khi đăng nhập thành công thì kiểm tra & cập nhật dữ liệu user
      await Firebase_Firestore().updateUserData();
    } catch (e) {
      throw exceptions(
        "Đăng nhập không thành công. Vui lòng kiểm tra lại",
      );
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: "375730189357-j7delqdu9p2gpa38odht09rs9lvs4d5r.apps.googleusercontent.com",
      );

      final account = await _googleSignIn.authenticate();

      final auth = account.authentication;
      final cre = GoogleAuthProvider.credential(idToken: auth.idToken);
      UserCredential userCredential= await _auth.signInWithCredential(cre);
      User? user = userCredential.user;

      if(user!=null){
        await Firebase_Firestore().saveGoogleUser(user);
      }return userCredential;
    } catch (e) {
      throw exceptions("Đăng nhập không thành công. Vui lòng thử lại.");
    }
  }


  Future<void> signOut() async{
    try{
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch(e){
      throw exceptions("Vui lòng thử lại.");
    }
  }


  ///Sign up
  Future<void> SignUp({
    required String email,
    required String password,
    required String confirm,
    required String username,
    File? profile,
  }) async {
    String URL;
    try {
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          username.isNotEmpty &&
          confirm.isNotEmpty) {
        if (password == confirm) {
          await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

          ///ảnh đại diện
          if (profile != null &&
              profile.path.isNotEmpty &&
              profile.existsSync()) {
            ///user chọn ảnh up lên firebase storage
            URL = await StorageMethod().uploadImageToStorage(
              'Profile',
              profile,
            );
          } else {
            ///nếu không, dùng ảnh mặc định
            URL = '';
          }

          /// lấy dữ liệu với firestore
          await Firebase_Firestore().CreateUser(
            email: email,
            username: username,
            profile: URL == ''
                ? 'https://firebasestorage.googleapis.com/v0/b/myoutfits-937e9.firebasestorage.app/o/person.png?alt=media&token=204a0a4f-ecc3-4599-b9a9-0edda28ca308'
                : URL,
          );


        } else {
          throw exceptions('Passsword và Confirm password không trùng nhau');
        }
      } else {
        throw exceptions('Vui lòng điền đầy đủ thông tin');
      }
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
    }
  }
}
