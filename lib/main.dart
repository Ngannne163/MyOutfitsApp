import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_outfits/data/view_model/filter_view_model.dart';
import 'package:my_outfits/data/view_model/following_view_model.dart';
import 'package:my_outfits/data/view_model/home_view_model.dart';
import 'package:my_outfits/data/view_model/profile_view_model.dart';
import 'package:my_outfits/data/view_model/search_view_model.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'data/view_model/create_post_view_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
        ChangeNotifierProvider(create: (_) => FilterViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => FollowingViewModel()),
        ChangeNotifierProvider(create: (_) => CreatePostViewModel()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Outfits',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: routes,
    );
  }
}
