import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  // Banner test IDs
  static const _testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIdIos = 'ca-app-pub-3940256099942544/2934735716';

  // Interstitial test IDs
  static const _testInterstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIdIos = 'ca-app-pub-3940256099942544/4411468910';

  // TODO: Replace with real ad unit IDs after AdMob registration
  static const _bannerIdAndroid = _testBannerIdAndroid;
  static const _bannerIdIos = _testBannerIdIos;
  static const _interstitialIdAndroid = _testInterstitialIdAndroid;
  static const _interstitialIdIos = _testInterstitialIdIos;

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return _bannerIdAndroid;
    if (Platform.isIOS) return _bannerIdIos;
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return _interstitialIdAndroid;
    if (Platform.isIOS) return _interstitialIdIos;
    throw UnsupportedError('Unsupported platform');
  }

  // Interstitial ad state
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoading = false;
  static int _showCount = 0;
  static DateTime? _lastShownAt;

  // Limits: max 3 per day, min 3 minutes between shows
  static const _maxDailyShows = 3;
  static const _minInterval = Duration(minutes: 3);
  static DateTime? _dailyResetDate;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _preloadInterstitial();
  }

  // Banner
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

  // Interstitial - preload
  static void _preloadInterstitial() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial(); // preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Show interstitial ad if available and within limits.
  /// Returns true if ad was shown.
  static Future<bool> showInterstitial() async {
    // Reset daily count if new day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_dailyResetDate == null || _dailyResetDate != today) {
      _dailyResetDate = today;
      _showCount = 0;
    }

    // Check daily limit
    if (_showCount >= _maxDailyShows) return false;

    // Check minimum interval
    if (_lastShownAt != null && now.difference(_lastShownAt!) < _minInterval) {
      return false;
    }

    // Show if loaded
    if (_interstitialAd != null) {
      _showCount++;
      _lastShownAt = now;
      await _interstitialAd!.show();
      return true;
    }

    // Not loaded yet, try preloading for next time
    _preloadInterstitial();
    return false;
  }
}
