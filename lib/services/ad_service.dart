import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  static const _testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIdIos = 'ca-app-pub-3940256099942544/2934735716';

  // TODO: Replace with real ad unit IDs after AdMob registration
  static const _bannerIdAndroid = _testBannerIdAndroid;
  static const _bannerIdIos = _testBannerIdIos;

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return _bannerIdAndroid;
    if (Platform.isIOS) return _bannerIdIos;
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
