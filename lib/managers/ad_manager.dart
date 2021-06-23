import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
class AdMobManager{
  //string for ids based on platform

  static var isInterstitialReady = false;
  static initialize(){
    if(MobileAds.instance == null){
      MobileAds.instance.initialize();
    }
  }

  static BannerAd createBannerAd(isLoaded) {
    BannerAd ad = new BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        request: AdRequest(),
        listener: AdListener(
            onAdLoaded: (Ad ad){
              print("banner loaded");
              isLoaded = true;
            },
            onAdFailedToLoad: (Ad ad, LoadAdError error){
              ad.dispose();
              print('Ad load failed (code=${error.code} message=${error.message})');
            }

        )
    );
    return ad;
  }

  static InterstitialAd interstitialAd;
  static InterstitialAd _createInterstitialAd(){
    return InterstitialAd(
        adUnitId: InterstitialAd.testAdUnitId,
        request: AdRequest(),
        listener: AdListener(
            onAdLoaded: (Ad ad){
              print('interstitial loaded');
              isInterstitialReady = true;
              //interstitialAd.show();
            },
            onAdClosed:(Ad ad){
              print('interstitial closed');
              isInterstitialReady = false;
              interstitialAd?.dispose();
            },
            onApplicationExit: (Ad ad) {
              print('interstitial: app exit');
              isInterstitialReady = false;
              interstitialAd?.dispose();
            }
        )
    );
  }

  static void showInterstitial(){
    interstitialAd?.dispose();
    interstitialAd = null;
    if(interstitialAd == null){
      interstitialAd = _createInterstitialAd();
      interstitialAd.load();
    }
  }

}