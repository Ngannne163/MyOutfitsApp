import 'package:flutter/material.dart';
import 'package:my_outfits/data/view_model/outfits_view_model.dart';
import 'package:my_outfits/util/save_Scipt_Tab.dart';
import 'package:provider/provider.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OutfitsViewModel({}),
      child: Consumer<OutfitsViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(
                    child: Text(
                      'Lưu trữ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Yêu thích',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: TabBarView(controller: _tabController, children: [
                  SavedGridTab(fetchData: viewModel.fetchSavedOutfits,
                    emptyMessage: 'Bạn chưa lưu bài viết nào.',
                    emptyIcon: Icons.bookmark_border,
                  ),
                  SavedGridTab(fetchData: viewModel.fetchLikedOutfits,
                    emptyMessage: 'Bạn chưa thích bài viết nào.',
                    emptyIcon: Icons.favorite_border,
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}



