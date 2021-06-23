import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_preferences.dart';
//TODO:: some stuff aren't wrapped in try catch. idk
class Authentication {
  static SnackBar customSnackBar({@required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  static Future<FirebaseApp> initializeFirebase() async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    User user = FirebaseAuth.instance.currentUser;//?

    ///if user already exists, go straight to user info screen
    if (user != null) {
      print('user is not null!');
      /* Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UserInfoScreen(
            user: user,
          ),
        ),
      );*/
    }

    return firebaseApp;
  }

  //signs in with both google and firebase
  static Future<User> signInWithGoogle({@required BuildContext context}) async {//User?
    FirebaseAuth auth = FirebaseAuth.instance;
    User user; //?

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();

      try {
        final UserCredential userCredential =
        await auth.signInWithPopup(authProvider);

        user = userCredential.user;
      } catch (e) {
        print(e);
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      //signs in with google
      final GoogleSignInAccount googleSignInAccount =//?
      await googleSignIn.signIn();

      //authentication. idk what this means
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential =
          await auth.signInWithCredential(credential);

          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Authentication.customSnackBar(
                content:
                'The account already exists with a different credential',
              ),
            );
          } else if (e.code == 'invalid-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Authentication.customSnackBar(
                content:
                'Error occurred while accessing credentials. Try again.',
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            Authentication.customSnackBar(
              content: 'Error occurred using Google Sign In. Try again.',
            ),
          );
        }
      }
    }

    return user;
  }

  //{@required BuildContext context}
  /* ScaffoldMessenger.of(context).showSnackBar(
        Authentication.customSnackBar(
          content: 'Error signing out. Try again.',
        ),
      );*/
  static Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('error signing out');

    }
  }

  /// Check If Document Exists
  static Future<bool> isFirstSignIn() async {
    print('isFirstSignIn called!');
    try {
      String uid = FirebaseAuth.instance.currentUser.uid;
      //print('UID is $uid - getting document reference');
      // Get reference to Firestore collection
      DocumentReference docReference = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid).collection('exists').doc('exists');

      //print('document reference acquired! getting document...');
      var doc = await docReference.get();
      var isFirstSignIn = false;
      if(!doc.exists){
        print('document does not exist yet!');
        isFirstSignIn = true;
        docReference.set({'isTrue':'true'});
      }
      return isFirstSignIn;
    } catch (e) {
      throw e;
    }
  }

  //TODO: connect to sqflite database
  //TODO: query all from selected database, convert to saveable format (json?), then batch update hihi
  Future<bool> batchUpdate(String id, String year, List jsonList) async {

    try {
      String uid = FirebaseAuth.instance.currentUser.uid;
      CollectionReference collectionReference = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection(year);
      var batch = FirebaseFirestore.instance.batch();
      for(var i = 0; i < jsonList.length; i++){
        batch.update(collectionReference.doc((i+1).toString()), jsonList[i]);
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }
}



class SignIn extends StatelessWidget {
  var settingsData;
  SignIn(this.settingsData);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Back up your data!"),
          ElevatedButton(
            child:Text('Google Sign in'),
            onPressed: () async {
              await Authentication.signInWithGoogle(context: context);
              //await Authentication.populateFirestore('2021');
              settingsData.isSignedIn = 1;
              await saveIntValue('isSignedIn', 1);
              //print('successfully authenticated and populated firestore with initial data!');
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Not Now'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );

  }

}