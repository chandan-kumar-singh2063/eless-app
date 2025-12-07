import 'package:hive/hive.dart';
import 'package:eless/model/ad_banner.dart';

class LocalAdBannerService {
  late Box<AdBanner> _adBannerBox;

  Future<void> init() async {
    try {
      _adBannerBox = await Hive.openBox<AdBanner>('AdBanners');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignAllAdBanners({required List<AdBanner> adBanners}) async {
    await _adBannerBox.clear();
    await _adBannerBox.addAll(adBanners);
  }

  List<AdBanner> getAdBanners() => _adBannerBox.values.toList();
}
