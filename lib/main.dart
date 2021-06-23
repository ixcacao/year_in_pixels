import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'colors_n_stuff.dart';
import 'managers/database_helper.dart';
import 'Screens/homepage.dart';
import 'Screens/settings.dart';
import 'Screens/insights.dart';
import 'managers/shared_preferences.dart';
import 'BLoC_stuff/pixel_bloc.dart';
import 'managers/notification_manager.dart';
import 'managers/ad_manager.dart';
import 'managers/authentication.dart';
import 'managers/subscription_manager.dart';
import 'BLoC_stuff/premium_bloc.dart';
import 'BLoC_stuff/name_bloc.dart';

FirebaseAnalytics analytics;

//List<PixelData> rawPixels = [];
/*
so ads set up is
metadata at androidmanifest
key/string at info.plist

* */

SettingsData settingsData;
class SettingsData{
  bool isPremium; //streambuilder
  var notifHour;
  var notifMinute;
  var username;
  bool notifications;
  bool isNightMode;
  var yearCheck;
  var lastSync;
  bool isSignedIn;
  var viewType;

  void initializeSettings() async {
    var thisYear = DateTime.now().year;
    this.viewType = await saveStringValue('viewType', 'year');
    this.isPremium = await saveBoolValue('premium', false);///
    this.isNightMode = await saveBoolValue('nightMode', false);///
    this.notifications = await saveBoolValue('notifications', true);///
    this.notifHour = await saveIntValue('notifHour', 6);
    this.notifMinute = await saveIntValue('notifMinute', 0);
    this.username = await saveStringValue('username', 'friend');
    this.yearCheck = await saveIntValue('yearCheck', thisYear);
    this.lastSync = await saveIntValue('lastSync', 0);
    this.isSignedIn = await saveBoolValue('isSignedIn', false);///
  }

   getValues() async {
    this.viewType = await getValue('viewType');
    this.isPremium = await getValue('premium');
    this.isNightMode = await getValue('nightMode');
    this.notifications = await getValue('notifications');
    this.notifHour = await getValue('notifHour');
    this.notifMinute = await getValue('notifMinute');
    this.username = await getValue('username');
    this.lastSync = await getValue('lastSync');
    this.isSignedIn = await getValue('isSignedIn');
  }

}
void main() async {
  var isFirstOpen = 0;
  settingsData = SettingsData();
  print('starting app!');
  WidgetsFlutterBinding.ensureInitialized();
  await Authentication.initializeFirebase();


  print('ads initialized!');
  var nightMode = await getValue('nightMode');
  if(nightMode == null){
    print('first time opening app!');
    isFirstOpen = 1;
    settingsData.initializeSettings();
    final helper = DatabaseHelper.instance;
    await helper.populate('moods', DateTime.now().year);
  }
  else
    {
     await settingsData.getValues();
  }
  if(!settingsData.isPremium){
    print('from initialization - premium is inactive! Initializing ads');
    AdMobManager.initialize();
  }
  initializeNotifs(settingsData.notifHour, settingsData.notifMinute);
  analytics = FirebaseAnalytics();
  await getRawPixels('moods').then(
      (rawPixels) {
        PixelsEvent.rawPixels = rawPixels;
            runApp(
            MaterialApp(
                theme: ThemeData(fontFamily: 'Montserrat', textTheme: TextTheme(bodyText1: TextStyle(), bodyText2: TextStyle(), button: TextStyle()).apply(bodyColor: bodyText, displayColor: bodyText ) ),
                home: isFirstOpen == 0 ? MyApp() : Name() )

          //isFirstOpen == 0 ? MyApp() : SignIn(settingsData)
        );
      }
  );
  print('rawPixels acquired! PixelsEvent.rawPixels is ${PixelsEvent.rawPixels}');
  //await getRawPixels('moods', rawPixels);


}

yearCheck(savedYear) async {
  var currentYear = DateTime.now().year;
  if( currentYear != savedYear){
    print('new year detected!');
    savedYear++;
    await saveIntValue('yearCheck', currentYear);
  }
}
getRawPixels(table) async {
  //this is so the real content starts at index 1
  PixelData fillerPixel;
  final helper = DatabaseHelper.instance;
  print('getting rawPixels from getRawPixels');
  return [fillerPixel] + await helper.queryAll(table);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var index = 1;
  //if user is in premium, sync data

  var updateType = settingsData.isPremium? 'sync' : 'initialization';
  final List<Widget> pages =  [
    LineChart(PixelsEvent.rawPixels),
    MyHomePage(rawPixels: PixelsEvent.rawPixels, viewType: settingsData.viewType),
    Settings(settingsData),
  ];
  @override
  Widget build(BuildContext context) {
    //print('building MaterialApp rawPixels to be passed to linechart is ${PixelsEvent.rawPixels}');

    return MultiBlocProvider(
        providers: [
          BlocProvider(
            //create bloc provider and add the correct initial data
            create: (BuildContext context) => PixelsBloc()..add(PixelsEvent(updateType: updateType)),
          ),
          BlocProvider(
            create: (BuildContext context) => UpdateSubscriptionBloc()..add(UpdateSubscriptionEvent(settingsData.isPremium)),
          ),
          BlocProvider(
            create: (BuildContext context) => NameBloc()..add(NameEvent(settingsData.username)),
          ),
        ],
        //builder
        child: Scaffold(
          //TODO:: convert list into function and add final keyword
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            onTap: (indexSelected) {
              setState(() {
                index = indexSelected;
              });
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.insights), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
            ],
            showSelectedLabels: false,
            showUnselectedLabels: false,
          ),
        )
    );
  }
}

class Name extends StatelessWidget {
  var textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            Text("What's your name"),
            TextField(controller: textController),
            ElevatedButton(onPressed: (){
              settingsData.username = textController.text;
              saveStringValue('username', textController.text);
              print('name ${textController.text} saved!');
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => MyApp()),
              );
            }, child: Text('Next'))
          ],
        )
    );
  }

}