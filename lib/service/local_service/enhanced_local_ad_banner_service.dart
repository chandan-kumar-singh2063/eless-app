import 'package:hive/hive.dart';
import 'package:eless/model/ad_banner.dart';

class EnhancedLocalAdBannerService {
  late Box<AdBanner> _adBannerBox;
  late Box<dynamic> _metadataBox;
  static const String _bannerBoxName = 'AdBanners';
  static const String _metadataBoxName = 'BannerMetadata';
  static const String _lastUpdateKey = 'last_update';

  Future<void> init() async {
    _adBannerBox = await Hive.openBox<AdBanner>(_bannerBoxName);
    _metadataBox = await Hive.openBox<dynamic>(_metadataBoxName);
  }

  Future<void> assignAllAdBanners({required List<AdBanner> adBanners}) async {
    await _adBannerBox.clear();
    await _adBannerBox.addAll(adBanners);
    // Store last update timestamp for cache management
    await _metadataBox.put(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  List<AdBanner> getAdBanners() => _adBannerBox.values.toList();

  bool shouldRefreshCache({Duration cacheValidDuration = const Duration(hours: 1)}) {
    final lastUpdate = _metadataBox.get(_lastUpdateKey);
    if (lastUpdate == null) return true;
    
    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate as int);
    final now = DateTime.now();
    
    return now.difference(lastUpdateTime) > cacheValidDuration;
  }

  Future<void> clearCache() async {
    await _adBannerBox.clear();
    await _metadataBox.clear();
  }

  DateTime? getLastUpdateTime() {
    final lastUpdate = _metadataBox.get(_lastUpdateKey);
    if (lastUpdate != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastUpdate as int);
    }
    return null;
  }

  bool get hasCachedData => getAdBanners().isNotEmpty;
}
