import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_outfits/data/firebase_servise/firebase_auth.dart';
import 'package:my_outfits/data/firebase_servise/firestore.dart';
import 'package:my_outfits/util/exception.dart';
import 'package:my_outfits/util/custom_button.dart';
import '../routes/app_routes.dart';
import '../util/dialog.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final height = TextEditingController();
  final age = TextEditingController();
  int currentIndex = 0;
  final PageController _pageController = PageController();
  int? _age;
  int? _height;
  String? _gender;
  List<String> _finalSelectedCategories = [];
  List<int> _selectedOutfitIds = [];
  final Firebase_Firestore _firebaseFirestore = Firebase_Firestore();
  List<Map<String, dynamic>> _styleOutfits = [];
  Map<String, int> _categoryCounts = {};

  void _analyzeCategories() {
    _categoryCounts = {};
    for (var category in _finalSelectedCategories) {
      _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
    }
    // Sắp xếp theo số lượng giảm dần
    _categoryCounts = Map.fromEntries(
      _categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  void _nextPage() {
    if (currentIndex < 3) {
      setState(() {
        currentIndex++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() async {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      if (_pageController.hasClients) {
        await _pageController.previousPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      try {
        await Authentication().signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } on exceptions catch (e) {
        dialogBuilder(context, e.message);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    height.dispose();
    age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF626487),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back, size: 40),
            ),

            const Text(
              'My Outfits',
              style: TextStyle(
                fontFamily: 'KaushanScript',
                fontSize: 30,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 50),
          ],
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4C6CD), Color(0xFFA4BEE0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _personalPage(),
              _genderPage(),
              _stylePage(),
              _resultPage(),
            ],
          ),
        ),
      ),
    );
  }

  ///màn hình chọn giới tính user
  Widget _genderPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Hãy chọn giới tính\n của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),

            Image.asset(
              "assets/image/quiz1.png",
              height: 250,
              width: 500,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 80),

            Column(
              children: [
                CustomButton(
                  text: 'nam',
                  onTap: () async {
                    _gender = 'man';
                    final outfitsData = await _firebaseFirestore.getOutfits(
                      _gender!,
                    );
                    setState(() {
                      _styleOutfits = outfitsData;
                      _selectedOutfitIds = [];
                    });
                    _nextPage();
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  "hoặc",
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                CustomButton(
                  text: 'nữ',
                  onTap: () async {
                    _gender = 'woman';
                    final outfitsData = await _firebaseFirestore.getOutfits(
                      _gender!,
                    );
                    setState(() {
                      _styleOutfits = outfitsData;
                      _selectedOutfitIds = [];
                    });
                    _nextPage();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ///màn hình thông tin cá nhân
  Widget _personalPage() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Nhập thông tin của bạn",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          Container(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      "Tuổi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),

                    const Text(
                      "Chiều cao",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 30),
                    Expanded(child: Textfield(age, '20 tuổi')),
                    const SizedBox(width: 30),
                    Expanded(child: Textfield(height, "150 cm")),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),

          CustomButton(
            text: 'Tiếp theo',
            onTap: () {
              _age = int.tryParse(age.text);
              _height = int.tryParse(height.text);
              if (_age != null && _height != null) {
                _nextPage();
              } else {
                dialogBuilder(context, "Vui lòng điền đầy đủ thông tin");
              }
            },
          ),
        ],
      ),
    );
  }

  /// màn hình chọn phong cách
  Widget _stylePage() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Chọn phong cách yêu thích\n của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: _styleOutfits.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.7, // Điều chỉnh tỷ lệ này để phù hợp
              ),
              itemBuilder: (context, index) {
                final outfit = _styleOutfits[index];
                final outfitID = outfit['id'] as int;
                final isSelected = _selectedOutfitIds.contains(outfitID);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedOutfitIds.remove(outfitID);
                      } else {
                        _selectedOutfitIds.add(outfitID);
                      }
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          outfit['imageURL'] ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (!isSelected)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),

                          child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          CustomButton(
            text: _selectedOutfitIds.length >= 5
                ? 'Tiếp theo'
                : 'Chọn ít nhất 5 phong cách',
            onTap: _selectedOutfitIds.length >= 5
                ? () {
              _finalSelectedCategories = [];
              for (var id in _selectedOutfitIds) {
                var outfit = _styleOutfits.firstWhere((o) => o['id'] == id);
                _finalSelectedCategories.addAll(List<String>.from(outfit['categories']));
              }
              _analyzeCategories();
              _nextPage();
            }
                : null,
            backgroundColor: _selectedOutfitIds.length >= 5 ? Colors.black : Colors.grey,
          ),
        ],
      ),
    );
  }

  ///màn hình đưa ra kết quả lựa chọn
  Widget _resultPage() {
    final sortedCategories = _categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    /// Nếu không có category nào, hiển thị thông báo
    if (sortedCategories.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu phong cách để hiển thị.',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    /// Lấy top 4 category phổ biến nhất để hiển thị
    final topCategories = sortedCategories.take(4).toList();

    /// Kích thước tối đa và tối thiểu cho các bong bóng
    const double maxSize = 185;
    const double minSize = 90;

    /// Danh sách các màu sắc cho bong bóng
    final List<Color> bubbleColors = [
      Color(0xBFB89CFF),
      Color(0xFF363636),
      Colors.blueGrey,
      Color(0xFF8B4562),
      Color(0xFFE74C56),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Phong cách của bạn:',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: Center(
              /// Sử dụng Wrap để các bong bóng tự động xuống dòng nếu không đủ không gian
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 20.0, /// Khoảng cách ngang giữa các bong bóng
                runSpacing: 20.0, /// Khoảng cách dọc giữa các bong bóng
                children: topCategories.asMap().entries.map((entry) {
                  final index =
                      entry.key; /// Vị trí của category trong danh sách top 4
                  final category = entry.value.key; // Tên của category
                  /// Tính toán kích thước bong bóng dựa trên vị trí (index), bong bóng đầu tiên sẽ lớn nhất
                  final size = maxSize - (index * 20);
                  final color =
                      bubbleColors[index %
                          bubbleColors.length]; /// Lấy màu sắc theo vòng lặp

                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle, /// Tạo hình tròn
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3), /// Đổ bóng
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          category, /// Chỉ hiển thị tên category
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                size /
                                7, /// Kích thước chữ nhỏ dần theo bong bóng
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          CustomButton(
            text: 'Hoàn thành',
            onTap: () async {
              if (_age != null && _height != null && _gender != null && _finalSelectedCategories.isNotEmpty) {
                try {
                  await _firebaseFirestore.saveQuizResult(
                    age: _age!,
                    height: _height!,
                    gender: _gender!,
                    selectedStyles: _finalSelectedCategories,
                  );
                  if (!mounted) return;
                  dialogBuilder(context, 'Thông tin của bạn đã được lưu thành công! 🎉');
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.mainscreen,
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  dialogBuilder(context, 'Lỗi khi lưu dữ liệu: ${e.toString()}');
                }
              } else {
                dialogBuilder(context, 'Vui lòng điền đầy đủ thông tin.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget Textfield(TextEditingController controller, String type) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: TextField(
        style: const TextStyle(fontSize: 18, color: Colors.black),
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, /// chỉ cho nhập số
        ],
        decoration: InputDecoration(
          hintText: type,
          hintStyle: TextStyle(color: Color(0xFF5C5C5C)),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }
}
