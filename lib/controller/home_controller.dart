import 'package:get/get.dart';
import 'package:eless/model/ad_banner.dart';
import 'package:eless/service/local_service/local_ad_banner_service.dart';
import 'package:eless/service/remote_service/remote_banner_service.dart';

class HomeController extends GetxController {
  static HomeController instance = Get.find();
  RxList<AdBanner> bannerList = List<AdBanner>.empty(growable: true).obs;
  RxBool isBannerLoading = false.obs;
  final LocalAdBannerService _localAdBannerService = LocalAdBannerService();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await _localAdBannerService.init();
    _loadCachedBanners(); // Load from cache first for instant UI

    // Fetch fresh data in background (don't block initialization)
    getAdBanners().catchError((e) {
      // User still sees cached data, no error shown
    });
  }

  void _loadCachedBanners() {
    if (_localAdBannerService.getAdBanners().isNotEmpty) {
      bannerList.assignAll(_localAdBannerService.getAdBanners());
    }
  }

  // Fetch fresh banners from API (called on pull-to-refresh)
  Future<void> getAdBanners() async {
    try {
      isBannerLoading(true);

      // Load from cache first for instant display
      if (_localAdBannerService.getAdBanners().isNotEmpty) {
        bannerList.assignAll(_localAdBannerService.getAdBanners());
      }

      // Then fetch fresh data from API
      var result = await RemoteBannerService().get();
      if (result != null && result.statusCode == 200) {
        try {
          // Check if response is valid JSON
          if (result.body.trim().startsWith('{') ||
              result.body.trim().startsWith('[')) {
            bannerList.assignAll(adBannerListFromJson(result.body));
            _localAdBannerService.assignAllAdBanners(
              adBanners: adBannerListFromJson(result.body),
            );
          } else {
          }
        } catch (e) {
        }
      } else {
      }
    } finally {
      isBannerLoading(false);
    }
  }
}
