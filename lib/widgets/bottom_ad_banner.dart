import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BottomAdBanner extends StatefulWidget {
  const BottomAdBanner({super.key});

  @override
  State<BottomAdBanner> createState() => _BottomAdBannerState();
}

class _BottomAdBannerState extends State<BottomAdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 테스트용 광고 ID (출시 전에는 이걸 써야 안전합니다)
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' 
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner, // 높이 50짜리 기본 배너 (방해 최소화)
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        // 광고 배경을 살짝 어둡게 처리해 앱 디자인과 이질감 줄임
        color: const Color(0xFF1E1E1E), 
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink(); // 로딩 전엔 공간 차지 안 함
  }
}