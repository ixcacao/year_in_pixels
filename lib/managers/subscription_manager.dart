import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';

Future<void> initPlatformState() async {
  var isPro;
  await Purchases.setDebugLogsEnabled(true);
  await Purchases.setup("SbHZyirtrOoQQaurDxzrUFVnWbmETuqk");

  PurchaserInfo purchaserInfo;
  try {
  purchaserInfo = await Purchases.getPurchaserInfo();
  print(purchaserInfo.toString());
  if (purchaserInfo.entitlements.all['all_features'] != null) {
  isPro = purchaserInfo.entitlements.all['all_features'].isActive;
  } else {
  isPro = false;
  }
  } on PlatformException catch (e) {
  print(e);
  }

  print('#### is user pro? $isPro');
}

Future<Offerings> fetchOfferings() async {
  Offerings offerings;
  try {
    offerings = await Purchases.getOfferings();
  } on PlatformException catch (e) {
    print(e);
  }
  return offerings;
}

//basically just the function wrapped in a try catch thing
Future<PurchaserInfo> purchasePackage(package) async {
  PurchaserInfo purchaserInfo;
  try {
    print('now trying to purchase');
    purchaserInfo = await Purchases.purchasePackage(package);
    print('purchase completed');


  } on PlatformException catch (e) {
    print('-----xx-----');
    var errorCode = PurchasesErrorHelper.getErrorCode(e);
    if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
      print("User cancelled");
    } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
      print("User not allowed to purchase");
    }
  }
  return purchaserInfo;
}
