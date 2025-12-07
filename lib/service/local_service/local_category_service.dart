import 'package:hive/hive.dart';

import '../../model/category.dart';

class LocalCategoryService {
  late Box<Category> _categoryBox;

  Future<void> init() async {
    try {
      _categoryBox = await Hive.openBox<Category>('categories');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignAllCategories({required List<Category> categories}) async {
    await _categoryBox.clear();
    await _categoryBox.addAll(categories);
  }

  List<Category> getCategories() => _categoryBox.values.toList();
}
