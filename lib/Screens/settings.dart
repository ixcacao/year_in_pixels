import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../BLoC_stuff/premium_bloc.dart';
import '../BLoC_stuff/pixel_bloc.dart';
import '../BLoC_stuff/name_bloc.dart';

import 'package:in_app_review/in_app_review.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../managers/authentication.dart';
import '../managers/subscription_manager.dart';
import '../managers/shared_preferences.dart';
import '../managers/notification_manager.dart';

import '../colors_n_stuff.dart';

class Settings extends StatefulWidget {
  var settingsData;
  Settings(this.settingsData);
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var extraZero;
  @override
  initState() {
    //if minutes is 2 digits, no need to add a zero before it (e.g. 11, 09)
    extraZero = widget.settingsData.notifMinute > 9 ? '' : '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg_top,
                    bg_top,
                    bg_mid,
                    bg_mid,
                    bg_bottom,
                  ]
              )
          ),
          child: Column(children: [
            Spacer(flex: 1),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(

                children: [
                  Text('Configuration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: MediaQuery.of(context).size.width/20)),
                  Row(children: [
                    Text('Name: '),
                    Builder(
                        builder:(blocContext){
                          return BlocBuilder<NameBloc, NameState>(
                              builder: (_, state){
                                return Row(
                                  children: [
                                    Text(state.name),
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () async {
                                        await showDialog(
                                            context: context, builder: (context) => renameDialog(context, blocContext, widget.settingsData));
                                      },
                                    ),
                                  ],
                                );
                              }
                          );
                        }
                    )
                  ]),
                  Row(children: [
                    Text('Notifications Enabled:  '),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: bg_top, elevation: 0),
                        child: Text(
                            '${widget.settingsData.notifHour} : $extraZero${widget.settingsData.notifMinute}',
                            style: TextStyle(color: Colors.black)),
                        onPressed: () async {
                          var timeSelected = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: widget.settingsData.notifHour,
                                  minute: widget.settingsData.notifMinute));
                          if (timeSelected != null) {
                            //save new notification time to shared preferences
                            await saveIntValue('notifHour', timeSelected.hour);
                            await saveIntValue('notifMinute', timeSelected.minute);

                            //renew notifications plugin
                            flutterLocalNotificationsPlugin.cancelAll();
                            await scheduleDailyNotification(widget.settingsData.notifHour,
                                widget.settingsData.notifMinute);

                            //setState so that the displayed value changes
                            setState(() {
                              widget.settingsData.notifHour = timeSelected.hour;
                              widget.settingsData.notifMinute = timeSelected.minute;
                            });
                            print(
                                "notifs scheduled to ${widget.settingsData.notifHour} : ${widget.settingsData.notifMinute} from timePicker");
                          }
                        }),
                    Checkbox(
                      activeColor: bg_bottom,
                      value: widget.settingsData.notifications,
                      onChanged: (value) async {
                        if (value) {
                          await scheduleDailyNotification(widget.settingsData.notifHour,
                              widget.settingsData.notifMinute);
                          await saveIntValue('notifications', 1);
                        } else {
                          flutterLocalNotificationsPlugin.cancelAll();
                          await saveIntValue('notifications', 0);
                        }
                      },
                    )
                  ]),
                  ElevatedButton(
                    child: Text('Rate App!', style: TextStyle(color: premiumLeft, fontWeight: FontWeight.w700)),

                    style: ElevatedButton.styleFrom( primary: Colors.transparent, shadowColor: Colors.transparent ),
                    onPressed: () {
                      final InAppReview inAppReview = InAppReview.instance;
                      inAppReview.openStoreListing();
                      //appStoreId: '...', microsoftStoreId: '...'
                    },
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child:ElevatedButton(
                        child: Text('Attribution', style: TextStyle(color: bodyText, decoration: TextDecoration.underline)),
                        style: ElevatedButton.styleFrom( primary: Colors.transparent, shadowColor: Colors.transparent ),
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              builder: (context) => attributionDialog(context));
                        })
                  )
                ]
              )
            ),
            Spacer(),
            Builder(
          builder: (blocContext) {
            return BlocBuilder<UpdateSubscriptionBloc, UpdateSubscriptionState>(
                builder: (_, state) {
                  if(state.isPremium != null) {
                    if (state.isPremium) {
                      return Column(
                        children: [
                          ElevatedButton(
                              child: Text('Reset Year'),
                              onPressed: () async {
                                await showDialog(
                                    context: context, builder: (context) => resetDialog(context, blocContext));
                              }),
                          ElevatedButton(
                              child: Text('Sync Data'),
                              onPressed: () async {
                                print('syncing data!');
                                BlocProvider.of<PixelsBloc>(blocContext)
                                    .add(PixelsEvent(updateType: 'sync'));
                              }),
                          ElevatedButton(
                              child: Text('Sign Out'),
                              onPressed: () async {
                                print('signing out!');
                                //BlocProvider.of<PixelsBloc>(blocContext)
                                //    .add(PixelsEvent(rawPixels, 'sync'));
                                BlocProvider.of<PixelsBloc>(blocContext)
                                    .add(PixelsEvent(updateType:'loading'));
                                BlocProvider.of<PixelsBloc>(blocContext)
                                    .add(PixelsEvent(updateType:'trueReset'));
                                widget.settingsData.isPremium = false;
                                saveBoolValue('isPremium', false);
                                BlocProvider.of<UpdateSubscriptionBloc>(blocContext)
                                    .add(UpdateSubscriptionEvent(false));

                                //Authentication.signOut(context: blocContext);
                                print('signed out!');
                                //Navigator.pop(blocContext);
                              }),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(onPrimary: Colors.white, primary: Colors.white, onSurface: Colors.transparent),
                                child: Text('Premium Settings'),
                                onPressed: () async {
                                  await showDialog(
                                      context: blocContext,
                                      builder: (context) =>
                                          premiumSettings(blocContext, widget.settingsData));
                                }),
                          )
                        ],
                      );
                    } else
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                              colors: [
                                premiumLeft,
                                premiumRight
                              ]
                          ),
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom( primary: Colors.transparent, shadowColor: Colors.transparent ),
                            child: Text('Get Premium', style: TextStyle(color: topText)),
                            onPressed: () async {
                              //Offerings offering = await fetchOfferings();
                              var offering;
                              await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      premiumDialog(context, offering, widget.settingsData, blocContext));
                            }),
                      );
                  } else return Text('update subscription state is still null');
                });
          }
      ),
            Spacer(flex: 5)

    ]),
        ));
  }
}

Widget premiumDialog(context, Offerings offering, settingsData, blocContext) {
  return AlertDialog(
      title: Text('Get Premium'),
      content: Column(children: [
        Text('pay me and be sexy'),
      ]),
      actions: [
        ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            }),
        ElevatedButton(
            child: Text('yes!!'),
            onPressed: () async {
              //revenuecat stuff                          //TODO:: Correct this.
              /*
          var _purchaserInfo = await purchasePackage(offering.current.monthly);
          if(_purchaserInfo.entitlements.all['all_features'].isActive){
            print('Premium successfully purchased');
            settingsData.isPremium = true;
            saveBoolValue('isPremium', true);
            BlocProvider.of<UpdateSubscriptionBloc>(context).add(UpdateSubscriptionEvent(true));
            print('Testing mode ~ Premium activated!');
          }
          */
              BlocProvider.of<PixelsBloc>(blocContext)
                  .add(PixelsEvent(updateType:'loading'));
              ///settingsData, sharedPref, and bloc instance is updated
              print('signing in...');
              await Authentication.signInWithGoogle(context: context);
              print('successfully signed in! checking if first sign in');

              var isFirstSignIn = await Authentication.isFirstSignIn();
              print('is first sign in is $isFirstSignIn');
              settingsData.isPremium = true;
              saveBoolValue('isPremium', true);
              BlocProvider.of<UpdateSubscriptionBloc>(blocContext)
                  .add(UpdateSubscriptionEvent(true));
              if (isFirstSignIn) {
                //sync data
                BlocProvider.of<PixelsBloc>(blocContext)
                    .add(PixelsEvent(updateType:'firstSync'));
              } else {
                BlocProvider.of<PixelsBloc>(blocContext)
                    .add(PixelsEvent(updateType:'restoreFirestore'));
                //await showDialog(
                //  context: context,
                //  builder: (context) => mergeDialog(context, blocContext),
                //);
                //mergeDialog(context, blocContext);
              }

              print('Pre-testing mode ~ Premium activated!');
            })
      ]);
}

Widget premiumSettings(context, settingsData) {
  return AlertDialog(
      title: Text('Premium Settings'),
      content: Column(children: [
        Text('how dare you'),
      ]),
      actions: [
        ElevatedButton(
            child: Text('Back'),
            onPressed: () {
              Navigator.pop(context);
            }),
        ElevatedButton(
            child: Text('Unsubscribe'),
            onPressed: () {
              settingsData.isPremium = false;
              saveBoolValue('isPremium', false);
              BlocProvider.of<UpdateSubscriptionBloc>(context)
                  .add(UpdateSubscriptionEvent(false));
              //TODO:: cancel premium in revenuecat
              Authentication.signOut();
              Navigator.pop(context);
            }),
      ]);
}

Widget renameDialog(context, blocContext, settingsData) {
  var usernameController = TextEditingController();
  return AlertDialog(
      title: Text('rename?'),
      content: Column(children: [
        TextField(
          controller: usernameController,
        )
      ]),
      actions: [
        ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            }),
        ElevatedButton(child: Text('Rename'), onPressed: () {
          settingsData.username = usernameController;
          saveStringValue('username', usernameController.text);
          BlocProvider.of<NameBloc>(blocContext).add(NameEvent(usernameController.text));
          print('name changed!');
        })
      ]);
}

Widget resetDialog(context, blocContext) {
  return AlertDialog(
      title: Text('turn a new page?'),
      content: Column(children: [
        Text('pay me and be sexy'),
      ]),
      actions: [
        ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            }),
        ElevatedButton(child: Text('yes!!'), onPressed: () {

          BlocProvider.of<PixelsBloc>(blocContext)
              .add(PixelsEvent(updateType:'reset'));
        })
      ]);
}

Widget attributionDialog(context) {
  return AlertDialog(
      title: Text('credits'),
      content: Column(children: [
        Text('Swagh'),
      ]),
      actions: [
        ElevatedButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            }),
        ElevatedButton(child: Text('yes!!'), onPressed: () {})
      ]);
}

Widget mergeDialog(context, blocContext) {
  return AlertDialog(
      title: Text('Keep Device Data?'),
      content: Column(children: [
        Text('Swagh'),
      ]),
      actions: [
        ElevatedButton(
            child: Text('Keep Existing Device Data and Sync with Cloud'),
            onPressed: () {
              BlocProvider.of<PixelsBloc>(blocContext)
                  .add(PixelsEvent(updateType: 'sync'));
            }),
        ElevatedButton(
            child: Text('Restore Cloud Data'),
            onPressed: () {
              BlocProvider.of<PixelsBloc>(blocContext)
                  .add(PixelsEvent(updateType:'restoreFirestore'));
            }),
      ]);
}
