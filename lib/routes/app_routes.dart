import 'package:flutter/material.dart';
import 'package:my_outfits/Screen/create_post_screen.dart';
import 'package:my_outfits/Screen/filter_screen.dart';
import 'package:my_outfits/Screen/home_screen.dart';
import 'package:my_outfits/Screen/login_screen.dart';
import 'package:my_outfits/Screen/main_screen.dart';
import 'package:my_outfits/Screen/profile_screen.dart';
import 'package:my_outfits/Screen/quiz_screen.dart';
import 'package:my_outfits/Screen/saved_screen.dart';
import 'package:my_outfits/Screen/search_screen.dart';
import 'package:my_outfits/Screen/signup_screen.dart';
import 'package:my_outfits/Screen/splash_screen.dart';
import 'package:my_outfits/auth/mainpage.dart';
import 'package:provider/provider.dart';
import '../Screen/edit_post_screen.dart';
import '../Screen/edit_profile_screen.dart';
import '../Screen/outfits_screen.dart';
import '../data/view_model/edit_post_view_model.dart';
import '../data/view_model/filter_view_model.dart';
import '../data/view_model/outfits_view_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String mainpage = '/mainpage';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String quiz = '/quiz';
  static const String home = '/home';
  static const String filter = '/filter';
  static const String search = '/search';
  static const String saved = '/saved';
  static const String profile = '/profile';
  static const String outfits = '/outfits';
  static const String createposts = '/createposts';
  static const String mainscreen = '/mainscreen';
  static const String editprofile = '/editprofile';
  static const String editpost = '/editpost';
}

final Map<String, WidgetBuilder> routes = {
  AppRoutes.splash: (context) => const SplashScreen(),
  AppRoutes.mainpage: (context) => const MainPage(),
  AppRoutes.mainscreen: (context) => const MainScreen(),
  AppRoutes.login: (context) => const LoginScreen(),
  AppRoutes.signup: (context) => const SignUpScreen(),
  AppRoutes.home: (context) => const HomeScreen(),
  AppRoutes.quiz: (context) => const QuizScreen(),
  AppRoutes.filter: (context) => const FilterScreen(),
  AppRoutes.search: (context) => const SearchScreen(),
  AppRoutes.profile: (context) => const ProfileScreen(),
  AppRoutes.saved: (context) => const SavedScreen(),
  AppRoutes.outfits: (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ChangeNotifierProvider(
      // ✅ Đảm bảo OutfitsViewModel được cung cấp
      create: (_) => OutfitsViewModel(args),
      child: OutfitsScreen(outfitData: args),
    );
  },
  AppRoutes.createposts: (context) => const CreatePostScreen(),
  AppRoutes.editprofile: (context) => const EditProfileScreen(),
  AppRoutes.editpost: (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ChangeNotifierProvider(
      create: (_) => EditPostViewModel(args),
      child: const EditPostScreen(),
    );
  },
};
