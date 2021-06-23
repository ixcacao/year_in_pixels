import 'package:shared_preferences/shared_preferences.dart';

//sharedpreferences
saveIntValue(key, int value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(key, value);
  return value;
}
saveStringValue(key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
  return value;
}
saveBoolValue(key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool(key, value);
  return value;
}
getValue(String key) async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var value = prefs.get(key);
  return value;
}