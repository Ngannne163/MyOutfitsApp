import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_servise/firebase_auth.dart';
import '../data/view_model/filter_view_model.dart';
import '../data/view_model/home_view_model.dart';
import '../data/view_model/profile_view_model.dart';
import '../routes/app_routes.dart';
import '../util/bottom_navigation_bar.dart';
import 'filter_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _logout() async {
    await Authentication().signOut();
    if (mounted){
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (Route<dynamic> route) => false,);
    }
  }

  void _onItemTapped(int index) {
    if (index == 3 && _selectedIndex != 3) {
      final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      profileViewModel.ProfileData();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _openFilterScreen(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) {
            final filterVM = FilterViewModel();
            filterVM.setInitialFilters(
              gender: homeViewModel.genderFilter,
              styles: homeViewModel.stylesFilter,
              places: homeViewModel.placesFilter,
              season: homeViewModel.seasonFilter,
              minHeight: homeViewModel.minHeightFilter,
              maxHeight: homeViewModel.maxHeightFilter,
            );
            return filterVM;
          },
          child: const FilterScreen(),
        ),
      ),
    );
  }


  List<PreferredSizeWidget?> get _appBars => [
    AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF8F8FF),
      elevation: 0,
      title: const Text(
        'My Outfits',
        style: TextStyle(
          fontFamily: 'KaushanScript',
          fontSize: 30,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _openFilterScreen(context),
          icon: const Icon(Icons.filter_list, size: 30, color: Colors.black),
        ),
      ],
    ),
    AppBar(
      title: const Text("Tìm kiếm"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF8F8FF),
      elevation: 0,
      title: const Text(
        'My Outfits',
        style: TextStyle(
          fontFamily: 'KaushanScript',
          fontSize: 30,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    AppBar(
      title: const Text("Trang cá nhân"),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
      ],
    ),
  ];

  // Các màn hình sẽ hiển thị trong body
  final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  /// FAB cho từng tab
  Widget? _buildFab(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return null;
      case 2:
        return null;
      case 3:
        return FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.createposts);
          },
          backgroundColor: Colors.pink.shade300,
          child: const Icon(Icons.add_a_photo, color: Colors.white),
        );
      default:
        return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBars[_selectedIndex],
      body: _pages[_selectedIndex], // Hiển thị màn hình theo index
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFab(_selectedIndex),
    );
  }


}