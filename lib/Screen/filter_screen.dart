import 'package:flutter/material.dart';
import 'package:my_outfits/data/view_model/home_view_model.dart';
import 'package:my_outfits/data/view_model/filter_view_model.dart';
import 'package:provider/provider.dart';
import '../util/custom_button.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}
class _FilterScreenState extends State<FilterScreen> {

  final Map<String, String> placesMap = const{
    'Biển': 'sea',
    'Cắm trại': 'campus',
    'Hẹn hò': 'date',
    'Cơ quan': 'office',
    'Du lịch': 'travel',
    'Cafe': 'cafe',
    'Tiệc': 'wedding',
    'Hằng ngày': 'daily',
    'Kỳ nghỉ': 'vacation'
  };

  final Map<String, String> seasonMap = const {
    'Mùa xuân': 'spring',
    'Mùa hạ': 'summer',
    'Mùa thu': 'autumn',
    'Mùa đông': 'winter',
  };

  final List<String> _stylesList = const [
    'streetwear',
    'romantic',
    'casual',
    'classic',
    'bohemian',
    'business',
    'sporty',
    'minimalist',
    'y2k',
    'unique',
    'retro',
    'vintage',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black),
          ),
          title: const Text('Lọc'),
          centerTitle: true,
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () {
                final homeViewModel = Provider.of<HomeViewModel>(
                  context,
                  listen: false,
                );
                final filterViewModel = Provider.of<FilterViewModel>(
                  context,
                  listen: false,
                );
                filterViewModel.resetFilter();
                homeViewModel.updateFilter(
                  gender: null,
                  places: [],
                  season: [],
                  styles: [],
                );
                Navigator.pop(context);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
        body: Consumer<FilterViewModel>(builder: (context, filterViewModel, child){
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Giới tính', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                _buildGenderOptions(filterViewModel),
                const SizedBox(height: 20,),
                const Text('Chiều cao', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                const SizedBox(height: 10,),
                _buildHeightSlider(filterViewModel),
                const SizedBox(height: 20,),
                const Text('Địa điểm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                const SizedBox(height: 20,),
                _buildFilterOptions(
                    options: placesMap.keys.toList(),
                    selectedOptions: filterViewModel.selectPlaces,
                    onToggle: filterViewModel.togglePlace,
                ),
                const SizedBox(height: 20),
                const Text('Mùa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20,),
                _buildFilterOptions(
                  options: seasonMap.keys.toList(),
                  selectedOptions: filterViewModel.selectSeason,
                  onToggle: filterViewModel.toggleSeason,
                ),
                const SizedBox(height: 20,),
                const Text('Phong cách', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20,),
                _buildStyleOptions(
                  options: _stylesList,
                  selectedOptions: filterViewModel.selectStyles,
                  onToggle: filterViewModel.toggleStyle,
                ),
                const SizedBox(height: 40),
                CustomButton(
                  onTap: () {
                    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
                    final filterViewModel = Provider.of<FilterViewModel>(context, listen: false);
                    homeViewModel.updateFilter(
                      gender: filterViewModel.selectGender,
                      places: filterViewModel.selectPlaces.toList(),
                      season: filterViewModel.selectSeason.toList(),
                      styles: filterViewModel.selectStyles.toList(),
                      minHeight: filterViewModel.minHeight,
                      maxHeight: filterViewModel.maxHeight,
                    );
                    Navigator.pop(context);
                  },
                  text: 'Apply',
                ),
              ],
            ),
          );
        },
        )
    );
  }

  Widget _buildHeightSlider(FilterViewModel viewModel) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${viewModel.minHeight.toInt()} cm'),
            Text('${viewModel.maxHeight.toInt()} cm'),
          ],
        ),
        RangeSlider(
          values: RangeValues(viewModel.minHeight, viewModel.maxHeight),
          min: 100,
          max: 220,
          divisions: 120,
          onChanged: (RangeValues newValues) {
            viewModel.updateHeight(newValues);
          },
        ),
      ],
    );
  }

  Widget _buildGenderOptions(FilterViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildGenderButton(viewModel, 'Man'),
        _buildGenderButton(viewModel, 'Woman'),
      ],
    );
  }

  Widget _buildGenderButton(FilterViewModel viewModel, String gender) {
    bool isSelected = viewModel.selectGender == gender.toLowerCase();
    return GestureDetector(
      onTap: () => viewModel.toggleGender(gender.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Colors.grey.shade600 : Colors.grey.shade200,
          border: Border.all(color: isSelected ? Colors.grey.shade600 : Colors.transparent),
        ),
        child: Text(gender,style: TextStyle(color: isSelected? Colors.white : Colors.black),),
      ),
    );
  }

  Widget _buildFilterOptions({
    required List<String> options,
    required Set<String> selectedOptions,
    required Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        // Kiểm tra option thuộc places, season hay style
        String? value;
        if (placesMap.containsKey(option)) {
          value = placesMap[option]; // sea, cafe...
        } else if (seasonMap.containsKey(option)) {
          value = seasonMap[option]; // spring, winter...
        } else {
          value = option; // styles giữ nguyên
        }

        bool isSelected = selectedOptions.contains(value);

        return GestureDetector(
          onTap: () {
            if (value != null) {
              onToggle(value); // gọi với value chuẩn
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? Colors.grey.shade600: Colors.grey.shade200,
              border: Border.all(color: isSelected ? Colors.grey.shade600 : Colors.transparent),
            ),
            child: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.black),),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStyleOptions({
    required List<String> options,
    required Set<String> selectedOptions,
    required Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        bool isSelected = selectedOptions.contains(option);

        return GestureDetector(
          onTap: () => onToggle(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? Colors.grey.shade600 : Colors.grey.shade200,
              border: Border.all(color: isSelected ? Colors.grey.shade600: Colors.transparent),
            ),
            child: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.black),),
          ),
        );
      }).toList(),
    );
  }
}