import 'package:get/get.dart';
import 'package:eless/model/category.dart';
import 'package:eless/service/local_service/local_category_service.dart';

class ExploreController extends GetxController {
  static ExploreController instance = Get.find();
  RxList<Category> categoryList = List<Category>.empty(growable: true).obs;
  final LocalCategoryService _localCategoryService = LocalCategoryService();
  RxBool isCategoryLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localCategoryService.init();
    _loadCachedCategories();
  }

  void _loadCachedCategories() {
    if (_localCategoryService.getCategories().isNotEmpty) {
      categoryList.assignAll(_localCategoryService.getCategories());
    }
  }

  // Category API removed - no category endpoint exists in backend
  // Events are displayed directly without categories
  void getCategories() async {
    // No-op: Backend doesn't have category endpoint
    // Events are managed by EventController
    isCategoryLoading(false);
  }
}
