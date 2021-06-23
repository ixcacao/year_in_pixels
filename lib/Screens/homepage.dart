import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../managers/database_helper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../BLoC_stuff/pixel_bloc.dart';
import '../BLoC_stuff/name_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../colors_n_stuff.dart';

final Color mood0 = Colors.white;
final Color mood1 = Colors.red;
final Color mood2 = Colors.orange;
final Color mood3 = Colors.yellow;
final Color mood4 = Colors.green;
final Color mood5 = Colors.blue;
final Color mood6 = Colors.indigo;
final Color mood7 = Colors.purple;

//List<PixelData> rawPixels = [];
List<PixelData> productivityPixels = [];
class MyHomePage extends StatefulWidget {
  List<PixelData> rawPixels;
  var viewType;
  MyHomePage({Key key, this.rawPixels, this.viewType}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState(this.rawPixels, this.viewType);
  //_MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final now = new DateTime.now();
  var rawPixels;
  var dayOfYear;
  var textEditingController;
  //class containing text input widget n methods
  var textInput;
  var dateRanges = [1, 31, 32, 59, 60, 90, 91, 120, 121, 151, 152, 181, 182, 212, 213, 243, 244, 273, 274, 304, 305, 334, 335, 365];


  //takes note of input
  var pixelInputNotifier;

  //final value to be set
  var pixelValueNotifier;

  var expansionNotifier = new ValueNotifier<String>('true');

  var imageNotifier;
  var isExpanded = true;
  var viewType = 'month';

  _MyHomePageState(this.rawPixels, this.viewType);
  //_MyHomePageState();
  //this needs to update regularly
  @override
  void initState() {
    print('initializing homepage - initial rawPixels is $rawPixels');
    dayOfYear = now.difference(new DateTime(now.year, 1, 1, 0, 0)).inDays + 1;
    if(now.year%4 == 0){
      print('issa leap year :/');
      dateRanges = [1, 31, 32, 60, 61, 91, 92, 121, 122, 152, 153, 182, 183, 213, 214, 244, 245, 274, 275, 305, 306, 335, 336, 366];
    }

    //daily input stuff

        textEditingController =
        new TextEditingController(text: rawPixels[dayOfYear].text);
        textInput = new TextInput(rawPixels[dayOfYear], textEditingController);
        imageNotifier = ValueNotifier<List<int>>(Uint8List.fromList(List<int>.from(rawPixels[dayOfYear].image)));
        pixelInputNotifier =
            ValueNotifier<int>(rawPixels[dayOfYear].intensity);
        pixelValueNotifier =
            ValueNotifier<int>(rawPixels[dayOfYear].intensity);
        print('rawPixels is $rawPixels with type ${rawPixels.runtimeType}');
        print('first day text is ${rawPixels[1].text}');

  }

  @override
  void dispose() {
    pixelInputNotifier.dispose();
    pixelValueNotifier.dispose();
    imageNotifier.dispose();
    super.dispose();
  }

  showPixelColumn(startRange, endRange, rawPixelsList, scrollDirection) {
    //print('LISTVIEW BUILDER : rawPixel dayOfYear intensity is ${rawPixelsList[dayOfYear].intensity}');
    //if present is within range, check each pixel in the month
    //if x == present, return special pixel (constructed within class)
    //this is so that other widgets have access to the present day pixel
    if (dayOfYear <= endRange && dayOfYear >= startRange) {
      //print('dayOfYear $dayOfYear is within endRange $endRange');
      print('itemcount is endRange - startRange + 1 or ${endRange - startRange + 1}');
      //print('FROM SHOWPIXELCOLUMN :: rawPixels is $rawPixels');
      return ListView.builder(
        scrollDirection: scrollDirection, //Axis.vertical
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: endRange - startRange + 1,
        itemBuilder: (context, index) {
          //print('building pixels... ${index + startRange} index');
          if (index + startRange == dayOfYear) {
            //print(' index + startRange == ${index + startRange} is equal to dayOfYear $dayOfYear ! ');
            return Container(
                height: MediaQuery.of(context).size.width/15,
                width: MediaQuery.of(context).size.width/15,
                child: ValueListenableBuilder(
                  valueListenable: pixelValueNotifier,
                  builder: (_, value, __) {
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          primary: Colors.purple,
                          backgroundColor: pixelColor(pixelValueNotifier.value),
                          elevation: 0,
                          padding: EdgeInsets.all(0)),
                      onPressed: () {
                        print('pressed today button');
                        rawPixelsList[index + startRange].intensity =
                            pixelValueNotifier.value;
                        //TODO:: just .. dont make this pressable i guess
                        pixelValueNotifier.value = 3;
                        //TODO :: update database
                      },
                      //child: Text(rawPixels[index + 1].intensity)
                    );
                  },
                ));
          } else {
            //print(' index + startRange == ${index + startRange} not equal to dayOfYear $dayOfYear');
            return Container(
              height: MediaQuery.of(context).size.width/15,
              width: MediaQuery.of(context).size.width/15,
              child: new Pixel(rawPixelsList[index + startRange]),
            );
          }
        },
      );
    }
    //else present day is not in range, print normal pixels
    else {
      //print('dayOfYear $dayOfYear is greater than endRange $endRange');
     // print('itemcount is endRange - startRange + 1 or ${endRange - startRange + 1}');
      return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        scrollDirection: scrollDirection,
        shrinkWrap: true,
        itemCount: endRange - startRange + 1,
        itemBuilder: (context, index) {
          var pixel = Pixel(rawPixelsList[index + startRange]);
          //print('building pixel with intensity... ${rawPixelsList[index + startRange].intensity}');
          return Container(
            height: MediaQuery.of(context).size.width/15,
            width: MediaQuery.of(context).size.width/15,
            child: pixel);
          //pixel.updateState();
        },
      );
    }
  }
  showPixels(range, rawPixelsList){
    if(range == 'year'){
      return Row(children: [
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: ListView.builder(
              itemCount: 31,
              itemBuilder: (context, index){
                return Container(
                height: MediaQuery.of(context).size.width/15,
                  child:Text((index+1).toString(), style: TextStyle(color: Colors.white))
                );
              }
            )),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[0], dateRanges[1], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[2], dateRanges[3], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[4], dateRanges[5], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[6], dateRanges[7], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[8], dateRanges[9], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[10], dateRanges[11], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[12], dateRanges[13], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[14], dateRanges[15], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[16], dateRanges[17], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[18], dateRanges[19], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[20], dateRanges[21], rawPixelsList, Axis.vertical)),
        Container(
            height: MediaQuery.of(context).size.width / 0.4,
            width: 30,
            child: showPixelColumn(dateRanges[22], dateRanges[23], rawPixelsList, Axis.vertical)),
      ]);
    }
    if(range == 'month'){
      var month = DateTime.now().month;
      var startRange = (2*month) - 2;
      var endRange = (2*month) - 1;
      return Column(children: [
        Container(
            height: 30,
            width:  MediaQuery.of(context).size.width / 1.2,
            child: showPixelColumn(dateRanges[startRange], dateRanges[startRange]+6, rawPixelsList, Axis.horizontal)),
        Container(
            height: 30,
            width:  MediaQuery.of(context).size.width / 1.2,
            child: showPixelColumn(dateRanges[startRange]+7, dateRanges[startRange]+13, rawPixelsList, Axis.horizontal)),
        Container(
            height: 30,
            width:  MediaQuery.of(context).size.width / 1.2,
            child: showPixelColumn(dateRanges[startRange]+14, dateRanges[startRange]+20, rawPixelsList, Axis.horizontal)),
        Container(
            height: 30,
            width:  MediaQuery.of(context).size.width / 1.2,
            child: showPixelColumn(dateRanges[startRange]+21, dateRanges[startRange]+27, rawPixelsList, Axis.horizontal)),
        Container(
            height: 30,
            width:  MediaQuery.of(context).size.width / 1.2,
            child: showPixelColumn(dateRanges[startRange]+28, dateRanges[endRange], rawPixelsList, Axis.horizontal)),
      ]);

    } else return Text('T-T');
  }
  Widget dailyInput(pixelToday, rawPixels) {
    //print('rebuilding dailyInput');
    textEditingController.text = pixelToday.text;
    imageNotifier.value = Uint8List.fromList(List<int>.from(pixelToday.image));
    pixelInputNotifier.value = pixelToday.intensity;
    pixelValueNotifier.value = pixelToday.intensity;
    var counter = 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),

        child: ValueListenableBuilder(
            valueListenable: expansionNotifier,
            builder: (_, value, __){
              return ExpansionTile(
                childrenPadding: const EdgeInsets.all(20),
                  key: Key(value),
                  title: Text('How was your day? lol', style: TextStyle(color: bodyText)),
                  initiallyExpanded: value == 'true',
                  children: [
                    inputIntensity(pixelInputNotifier, pixelToday, context),
                    inputImage(imageNotifier, pixelToday),
                    textInput.inputText(),
                    DecoratedBox(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: bg_bottom),
                      child: ElevatedButton(
                        child: Text('Done'),
                        style: ElevatedButton.styleFrom(
                          shadowColor: Colors.transparent,
                          primary: Colors.transparent
                        ),
                        onPressed: () async {
                          pixelValueNotifier.value = pixelInputNotifier.value;
                          //change pixel's values to what the user set
                          pixelToday.text = textEditingController.text;
                          pixelToday.intensity = pixelInputNotifier.value;
                          pixelToday.image = imageNotifier.value;
                          pixelToday.timestamp = DateTime.now().millisecondsSinceEpoch;
                          //update pixel in database
                          updatePixel('moods', dayOfYear, pixelToday);

                          PixelsEvent.rawPixels[dayOfYear] = pixelToday;
                          BlocProvider.of<PixelsBloc>(context).add(PixelsEvent(updateType: 'localChange'));
                          print(
                              'updated Pixel! Text: ${pixelToday.text}, intensity: ${pixelToday.intensity}');
                          //make expansionTile close
                          expansionNotifier.value = 'false' + counter.toString();
                          counter++;

                        },
                      ),
                    )
                  ]);
            }
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    print('building homepage... again.');
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
        child: Builder(
            builder: (context) {

              return BlocBuilder<PixelsBloc, PixelsState>(

                builder: (_, state){
                  //print('HOMEPAGE BLOCBUILDER: day 1 intensity is ${state.rawPixels[1].intensity}');
                  //rawPixels is ${state.rawPixels}
                  if(state.rawPixels != null && state.updateType != 'loading'){
                    var rawPixelsList = state.rawPixels;
                    return ListView(
                      shrinkWrap: true,
                        children: [
                          const SizedBox(height: 50),

                          BlocBuilder<NameBloc, NameState>(
                              builder: (_, state){
                                return Text('hello, ' + state.name);
                              }
                          ),
                          dailyInput(state.rawPixels[dayOfYear], state.rawPixels),
                  Row(children: [
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: ListView.builder(
                  itemCount: 31,
                  itemBuilder: (context, index){
                  return Container(
                  height: MediaQuery.of(context).size.width/15,
                  child:Text((index+1).toString(), style: TextStyle(color: Colors.white))
                  );
                  }
                  )),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[0], dateRanges[1], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[2], dateRanges[3], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[4], dateRanges[5], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[6], dateRanges[7], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[8], dateRanges[9], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[10], dateRanges[11], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[12], dateRanges[13], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[14], dateRanges[15], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[16], dateRanges[17], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[18], dateRanges[19], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[20], dateRanges[21], rawPixelsList, Axis.vertical)),
                  Container(
                  height: MediaQuery.of(context).size.width / 0.4,
                  width: 30,
                  child: showPixelColumn(dateRanges[22], dateRanges[23], rawPixelsList, Axis.vertical)),
                  ]),
                          //showPixels(viewType, state.rawPixels),
                  ]
                    );
                  } else return CircularProgressIndicator();
                },
                buildWhen: (_, presentState){
                  if(presentState.updateType == 'localChange'){
                    print('from homepage blocbuilder: update type is localChange. not rebuilding');
                    return false;
                  } else return true;
                },
              );
            }
        ),
      )
    );
  }
}

class Pixel extends StatefulWidget {
  PixelData pixelData;
  Pixel(this.pixelData, {Key key}) : super(key: key);
  @override
  _PixelState createState() => _PixelState();
}

class _PixelState extends State<Pixel> {
  //PixelData pixelData; this.pixelData

  _PixelState();
  final picker = ImagePicker();
  var imageNotifier;
  var pixelValueNotifier;

  var textEditingController;


  @override
  void didUpdateWidget(covariant Pixel oldWidget) {
    super.didUpdateWidget(oldWidget);

    imageNotifier.value = Uint8List.fromList(List<int>.from(widget.pixelData.image));
    textEditingController = new TextEditingController(text: widget.pixelData.text);
    pixelValueNotifier = ValueNotifier<int>(widget.pixelData.intensity);
    //print('didUpdateWidget: image notifier value type is ${imageNotifier.value.runtimeType}');
      //setState(() {
      //  print('SETSTATE CALLED day ${pixelData.day} updated with intensity ${pixelData.intensity} ');
      //});
  }

  @override
  void initState() {
    //print('FROM INDIVIDUAL PIXEL :: pixelday is day ${widget.pixelData.day} with id ${widget.pixelData.id}');
    imageNotifier = ValueNotifier<List<int>>(Uint8List.fromList(List<int>.from(widget.pixelData.image)));
    textEditingController = new TextEditingController(text: widget.pixelData.text);
    pixelValueNotifier = ValueNotifier<int>(widget.pixelData.intensity);
    super.initState();
    //print('FROM INDIVIDUAL PIXEL :: NOTIFIERS SET!!');
  }

  pixelDialog() {
    print('FROM INDIVIDUAL PIXEL :: Pixel dialog called!');
    var date = DateTime(DateTime.now().year, 1, 0, 0, 0).add(Duration(days: widget.pixelData.day));
    var textInput = new TextInput(widget.pixelData, textEditingController);
    var dialog = AlertDialog(
        title: Text('$date'),
        content: Column(children: [
          //add textfield, image button, and gesture buttons
          inputIntensity(pixelValueNotifier, widget.pixelData, context),
          inputImage(imageNotifier, widget.pixelData),
          textInput.inputText(),
          DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: bodyText),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shadowColor: Colors.transparent,
                  primary: Colors.transparent
              ),
              child: Text('Save'),
              onPressed: () {
                // TODO :: pop
                ///updates pixel value
                widget.pixelData.text = textEditingController.text;
                widget.pixelData.intensity = pixelValueNotifier.value;
                widget.pixelData.image = imageNotifier.value;
                widget.pixelData.timestamp = DateTime.now().millisecondsSinceEpoch;

                ///updates database with updated pixel
                updatePixel('moods', widget.pixelData.id, widget.pixelData);

                ///updates static variable PixelsEvent.rawPixels with new pixels
                PixelsEvent.rawPixels[widget.pixelData.day] = widget.pixelData;

                ///so that it can be passed as a parameter to update the bloc in the insights page
                BlocProvider.of<PixelsBloc>(context).add(PixelsEvent(updateType: 'localChange'));
                print('updated Pixel! Text: ${widget.pixelData.text}, intensity: ${widget.pixelData.intensity}');

                setState(() {
                  widget.pixelData.intensity = pixelValueNotifier.value;
                });
                Navigator.of(context).pop;
              },
            ),
          )
        ]));
    showDialog(
        context: context,
        builder: (context) {
          return dialog;
        });
  }

  @override
  Widget build(BuildContext context) {
    //print('rebuilding pixel day ${widget.pixelData.day} with id ${widget.pixelData.id}');
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide.none,
          primary: Colors.purple,
          backgroundColor: pixelColor(widget.pixelData.intensity),
          elevation: 0,
          padding: EdgeInsets.all(0)),
      onPressed: () {
        pixelDialog();
      },
      //child: Text(rawPixels[index + 1].intensity)
    );
  }
}

///Pixel management functions!!

Widget inputImage(imageNotifier, pixelData) {
  //print('INPUT IMAGE CALLED');
  return Container(
      child: ValueListenableBuilder(
          valueListenable: imageNotifier,
          builder: (_, value, __) {
            if (value.length < 3) {
              return ElevatedButton(
                  child: Text('add image'),
                  onPressed: () async {
                    await getCompressedImage(imageNotifier, pixelData);
                  });
            } else
             // Iterable listInt =
              print('IMAGE NOTIFIER value is not null! it is ${imageNotifier.value}');
              //List<int> listInt = List<int>.from(imageNotifier.value);
              return Column(children: [
                Image.memory(Uint8List.fromList(imageNotifier.value), width: 100, height: 100),
                ElevatedButton(
                  child: Text('edit image'),
                  onPressed: () async {
                    await getCompressedImage(imageNotifier, pixelData);
                  },
                )
              ]);
          }));
}

Future getCompressedImage(imageNotifier, pixelData) async {
  final picker = ImagePicker();
  final pickedFile = await picker.getImage(source: ImageSource.gallery);
  var fileVersion = File(pickedFile.path);

  //gets the index of . in .png
  var dotIndex = fileVersion.absolute.path.lastIndexOf('.');

  //.jpg, .png, etc.
  var imageType = fileVersion.absolute.path.substring(dotIndex);
  //path without file extension
  var rawPath = fileVersion.absolute.path.substring(0, dotIndex);
  //basically same path with another thing
  var targetPath = rawPath + '_compressed' + imageType;

  print('target path is $targetPath');

  var compressedImage = await FlutterImageCompress.compressWithFile(
    fileVersion.absolute.path,
    quality: 50,
  );

  imageNotifier.value = compressedImage;
  print('imageNotifier.value is ${imageNotifier.value}');
}

class TextInput {
  var pixelData;
  var textFieldController;
  TextInput(this.pixelData, this.textFieldController);

  Widget inputText() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextField(controller: textFieldController,
        decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bodyText))),),
    );
  }
}

Widget inputIntensity(pixelInputNotifier, pixelData, context) {
  var dimensions = MediaQuery.of(context).size.width/15;
  const margins = 3.0;
  return ValueListenableBuilder(
      valueListenable: pixelInputNotifier,
      builder: (_, value, __) {
        return Row(children: [
          Container(
            margin: const EdgeInsets.all(margins),
            width: dimensions,
            child: ElevatedButton(
              child: Text('$value'),
              style: ElevatedButton.styleFrom(
                  primary: value == 1 ? Colors.red : Colors.white),
              onPressed: () {
                pixelInputNotifier.value = 1;
              },
            ),
          ),
          Container(
              margin: const EdgeInsets.all(margins),
              width: dimensions,
              child: ElevatedButton(
                child: Text('$value'),
                style: ElevatedButton.styleFrom(
                    primary: value == 2 ? Colors.orange : Colors.white),
                onPressed: () {
                  pixelInputNotifier.value = 2;
                },
              )),
          Container(
              margin: const EdgeInsets.all(margins),
              width: dimensions,
              child: ElevatedButton(
                child: Text('$value'),
                style: ElevatedButton.styleFrom(
                    primary: value == 3 ? Colors.yellow : Colors.white),
                onPressed: () {
                  pixelInputNotifier.value = 3;
                },
              )),
          Container(
              margin: const EdgeInsets.all(margins),
              width: dimensions,
              child: ElevatedButton(
                child: Text('$value'),
                style: ElevatedButton.styleFrom(
                    primary: value == 4 ? Colors.green : Colors.white),
                onPressed: () {
                  pixelInputNotifier.value = 4;
                },
              )),
          Container(
              margin: const EdgeInsets.all(margins),
              width: dimensions,
              child: ElevatedButton(
                child: Text('$value'),
                style: ElevatedButton.styleFrom(
                    primary: value == 5 ? Colors.blue : Colors.white),
                onPressed: () {
                  pixelInputNotifier.value = 5;
                },
              )),
          Container(
            margin: const EdgeInsets.all(margins),
            width: dimensions,
            child: ElevatedButton(
              child: Text('$value'),
              style: ElevatedButton.styleFrom(
                  primary: value == 6 ? Colors.indigo : Colors.white),
              onPressed: () {
                pixelInputNotifier.value = 6;
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(margins),
            width: dimensions,
            child: ElevatedButton(
              child: Text('$value'),
              style: ElevatedButton.styleFrom(
                  primary: value == 7 ? Colors.purple : Colors.white),
              onPressed: () {
                pixelInputNotifier.value = 7;
              },
            ),
          ),
        ]);
      });
}

pixelColor(intensity) {
  switch (intensity) {
    case 0:
      return mood0;
      break;
    case 1:
      return mood1;
      break;
    case 2:
      return mood2;
      break;
    case 3:
      return mood3;
      break;
    case 4:
      return mood4;
      break;
    case 5:
      return mood5;
      break;
    case 6:
      return mood6;
      break;
    case 7:
      return mood7;
      break;
    default:
      return mood0;
      break;
  }
}

updatePixel(String table, int id, PixelData pixelData) async {
  final helper = DatabaseHelper.instance;
  int count = await helper.update(table, id, pixelData);

  print(
      'updated $count row(s) with amount ${pixelData.intensity}, on day ${pixelData.day} with id ${pixelData.id}');
}