import 'package:get/get.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  final RxInt selectedBgIndex = 0.obs;

  final List<String> bgImages = const [
    'assets/images/bg_premium_dark.png',
    'assets/images/bg_abstract_glass.png',
    'assets/images/bg_neon_mesh.png',
  ];

  String get currentBgImage => bgImages[selectedBgIndex.value];

  void changeBackground(int index) {
    if (index >= 0 && index < bgImages.length) {
      selectedBgIndex.value = index;
    }
  }
}
