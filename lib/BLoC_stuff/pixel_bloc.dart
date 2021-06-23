import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../managers/database_helper.dart';
import '../managers/authentication.dart';
///sync bloc: to be used on app start(if premium), when the user restores purchase/ signs in, or when the user manually syncs

//the whole thing is rebuilt

class PixelsEvent {
  static var rawPixels;
  final String updateType;
  //final pixelData;
  PixelsEvent({@required this.updateType});


}


class PixelsState {
  final rawPixels;
  final String updateType;
  PixelsState(this.rawPixels, this.updateType);
}

class PixelsBloc extends Bloc<PixelsEvent, PixelsState> {

  PixelsBloc() : super(PixelsState(null, 'localChange'));

  @override
  Stream<PixelsState> mapEventToState(PixelsEvent event) async* {
    ///should all the business logic be here??? that would mean that the sync events only function is to notify. oh and provide the original data i guess
    var newRawPixels;
    if(event.updateType == 'loading'){
      print('pixelsbloc event called! event type is LOADING');
      yield PixelsState(PixelsEvent.rawPixels, 'loading');
    }
    if(event.updateType == 'formatChange'){
      print('pixelsbloc event called! event type is FORMAT CHANGE');
      yield PixelsState(PixelsEvent.rawPixels, 'formatChange');
    }

    if(event.updateType == 'sync'){
      print('pixelsbloc event called! event type is SYNC');
      newRawPixels = await syncData(PixelsEvent.rawPixels);
      yield PixelsState(newRawPixels, 'sync');
    }
    if(event.updateType == 'initialization'){
      print('pixelsbloc event called! event type is INITIALIZATION');

      yield PixelsState(PixelsEvent.rawPixels, 'initialization');
    }
    if(event.updateType == 'firstSync'){
      print('pixelsbloc event called! event type is FIRST SYNC');
      await firstSync(PixelsEvent.rawPixels);
      yield PixelsState(PixelsEvent.rawPixels, 'firstSync');
    }
    else if(event.updateType == 'reset') {
      print('pixelsbloc event called! event type is RESET');
      newRawPixels = await resetData(PixelsEvent.rawPixels, 'reset');
      yield PixelsState(newRawPixels, 'reset');
    }
    else if(event.updateType == 'trueReset') {
      print('pixelsbloc event called! event type is TRUE RESET (on sign out)');
      await syncData(PixelsEvent.rawPixels);
      newRawPixels = await resetData(PixelsEvent.rawPixels, 'trueReset');
      Authentication.signOut();
      print('TRUERESET pixel day 1 intensity is ${newRawPixels[1].intensity}');
      yield PixelsState(newRawPixels, 'trueReset');
    }
    else if(event.updateType == 'localChange'){
      print('pixelsbloc event called! event type is LOCAL CHANGE');
      yield PixelsState(PixelsEvent.rawPixels, 'localChange');
    }
    if(event.updateType == 'restoreFirestore'){
      print('pixelsbloc event called! event type is RESTORE FIRESTORE (true reset + sync function)');
      var tempRawPixels = await resetData(PixelsEvent.rawPixels, 'trueReset');
      newRawPixels = await syncData(tempRawPixels);
      yield PixelsState(newRawPixels, 'trueReset');
    }
     //so is the rawPixels global variable really needed? oh yeah for the local stuff. but....

  }

}
//TODO:: wrap with try catches here


//returns a list of maps
Future queryAll(year) async {
  String uid = FirebaseAuth.instance.currentUser.uid;
  CollectionReference collectionReference = FirebaseFirestore.instance
      .collection('Users')
      .doc(uid)
      .collection(year);
  QuerySnapshot<Object> querySnapshot = await collectionReference.get();
  //generates list of maps
  List<Object> allData = querySnapshot.docs.map((doc) => doc.data()).toList();
  //print('FROM QUERYALL IN PIXELBLOC :: sample data is ${allData[0]}');
  return allData;

}

//will only be called when the user is signed in
//modifies rawPixels
syncData(rawPixels) async {
  // TODO:: test this SKDGASFKDFJSKGSJ
  //get batch of firestore data if possible ,, turn data into objects or something
  //for each rawPixel, check if corresponding object exists
  //if null and the rawPixel has a timestamp, update
  //if it exists, compare timestamps
  //if firestore is more recent, change database and rawPixels
  //if database is more recent, update firestore

  List orderedList = List.generate(367, (_) => 0);
  //print('from syncData: initial ordered list is $orderedList');


  var year = rawPixels[5].year.toString(); //TODO : change this
  var firestoreData = await queryAll(year);
  print('from syncData: firestoreData is $firestoreData');

  if(firestoreData != []){
    //insert firestore data into ordered list
    for(var i = 0; i < firestoreData.length; i++) {

      var day = firestoreData[i]['day'];
      orderedList[day] = firestoreData[i];
      print('FROM SYNCDATA: FIRESTORE DATA DAY IS ${firestoreData[i]['day']}');

    }
  }
  print('from syncData: updated ordered list is $orderedList');

  //print('from SYNCDATA: rawPixels length is ${rawPixels.length}');

  String uid = FirebaseAuth.instance.currentUser.uid;
  var batch = FirebaseFirestore.instance.batch();
  CollectionReference collectionReference = FirebaseFirestore.instance
      .collection('Users')
      .doc(uid)
      .collection(year);
  final helper = DatabaseHelper.instance;
  //TODO:: fix this           \/\/\/ -- adjusted
  for(var i = 1; i < rawPixels.length; i++ ){
    print(' rawpixels day is ${rawPixels[i].day} with id ${rawPixels[i].id} with timestamp ${rawPixels[i].timestamp} while orderedList[i] is ${orderedList[i]}');
    if(orderedList[i] != 0){
      //for each rawPixel, if the corresponding firestore map exists ->> check if corresponding rawPixel isnt empty
      //  if not empty, compare timestamps and update according to which source has the most recent data
      // if empty, set firestore data
      print('orderedList[i] day is ${orderedList[i]['day']} with id ${orderedList[i]['id']} while rawpixels day is ${rawPixels[i].day} with id ${rawPixels[i].id} with timestamp ${rawPixels[i].timestamp} ');
      if(rawPixels[i].timestamp != 0){
        print('rawPixels timestamp is not zero! comparing timestamps...');
        //where the device's data is more recent
        if(rawPixels[i].timestamp > orderedList[i]['timestamp']){
          print('device data day ${rawPixels[i].day} timestamp : ${rawPixels[i].timestamp} is more recent! updating firestore');
          //update firestore
          batch.set(collectionReference.doc(i.toString()), {'year': rawPixels[i].year, 'intensity': rawPixels[i].intensity, 'day': rawPixels[i].day, 'image': rawPixels[i].image, 'text': rawPixels[i].text, 'id': rawPixels[i].id, 'timestamp' : rawPixels[i].timestamp});
        }

        //where firestore data is more recent
        if(rawPixels[i].timestamp < orderedList[i]['timestamp']){
          print('device timestamp not zero - firestore data is more recent! updating device');
          //update rawPixels and database
          var newPixelData = PixelData.fromMap(orderedList[i]);
          await helper.update('moods', orderedList[i]['id'], newPixelData);
          rawPixels[i] = newPixelData;
        }

      }
      else {
        print('device data day ${rawPixels[i].day} timestamp is zero! firestore data exists and is more recent -  updating device');
        //update rawPixels and database
        var newPixelData = PixelData.fromMap(orderedList[i]);
        await helper.update('moods', orderedList[i]['id'], newPixelData);
        rawPixels[i] = newPixelData;
      }

    } else {   //if it doesn't exist, check if  the rawPixel needs to be synced
      if(rawPixels[i].timestamp != 0){
        print('no firestore data yet for ${rawPixels[i].day}. device timestamp not zero - setting firestore');
        batch.set(collectionReference.doc(i.toString()), {'year': rawPixels[i].year, 'intensity': rawPixels[i].intensity, 'day': rawPixels[i].day, 'image': rawPixels[i].image, 'text': rawPixels[i].text, 'id': rawPixels[i].id, 'timestamp' : rawPixels[i].timestamp});
      }
    }
    //batch.set(collectionReference.doc(i.toString()), {'year': year, 'intensity': 0, 'day': i, 'image': '', 'text': ''}) ;
  }
  await batch.commit();

  print('type: SYNC successfully synced!');
  return rawPixels;
}
//does not modify rawPixels
firstSync(rawPixels) async {
  print('First sync called!');
  var year = rawPixels[5].year.toString(); //TODO : change this
  String uid = FirebaseAuth.instance.currentUser.uid;
  print('UID is $uid - getting document reference');
  var batch = FirebaseFirestore.instance.batch();
  CollectionReference collectionReference = FirebaseFirestore.instance
      .collection('Users')
      .doc(uid)
      .collection(year);
  print('FROM FIRST SYNC : rawpixels length is ${rawPixels.length}');
  //TODO:: fix this           \/\/\/ -- adjusted
  for(var i = 1; i < rawPixels.length; i++ ){

    print('rawPixels[$i] is ${rawPixels[i]}, timestamp is ${rawPixels[i].timestamp}');
      if(rawPixels[i].timestamp != 0){
        batch.set(collectionReference.doc(i.toString()), {'year': rawPixels[i].year, 'intensity': rawPixels[i].intensity, 'day': rawPixels[i].day, 'image': rawPixels[i].image, 'text': rawPixels[i].text, 'id': rawPixels[i].id, 'timestamp' : rawPixels[i].timestamp});
        print('FIRST SYNC SET');

      }

    }
    //batch.set(collectionReference.doc(i.toString()), {'year': year, 'intensity': 0, 'day': i, 'image': '', 'text': ''}) ;
  await batch.commit();
  print('FIRST SYNC successfully synced!');
}
//resets data in database and returns a rawPixels list with the new values
//modifies rawPixels
Future resetData(rawPixels, String resetType) async {
  PixelData fillerPixel;
  //if it's a true reset, all the database values - including timestamp - will be set to their default values
  var timestamp = resetType == 'trueReset' ? 0 : DateTime.now().millisecondsSinceEpoch;
  print('from RESETDATA: reset type is $resetType, date is $timestamp');
  final helper = DatabaseHelper.instance;
  //var currentYear = DateTime.now().year;
  //if(rawPixels[5].year < currentYear){
  // copy rawpixels to finished database
  //helper.copyTable('moods', 'moodsFinished');
  // }
  var pixelsList = await helper.resetValues('moods', DateTime.now().year, timestamp);
  PixelsEvent.rawPixels = [fillerPixel] + pixelsList;
  print('FROM RESETDATA PixelsEvent.rawPixels day ${PixelsEvent.rawPixels[1].day} with id ${PixelsEvent.rawPixels[1].id} timestamp is ${PixelsEvent.rawPixels[1].timestamp} with intensity ${PixelsEvent.rawPixels[1].intensity}');
  return PixelsEvent.rawPixels;
}

