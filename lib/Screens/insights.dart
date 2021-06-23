import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stats/stats.dart';
import '../BLoC_stuff/premium_bloc.dart';
import '../managers/ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../BLoC_stuff/pixel_bloc.dart';
import '../colors_n_stuff.dart';

class PixelDatum {
  final int x;
  final int y;

  PixelDatum(this.x, this.y);
}


class LineChart extends StatefulWidget {
  final now = new DateTime.now();
  var currentMonth;
  var rawPixels;
  LineChart(this.rawPixels);

  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {


  BannerAd _ad;
  bool _isAdLoaded = false;

  var startRange = 0;
  var endRange = 365;
  var dateRanges = [1, 31, 32, 59, 60, 90, 91, 120, 121, 151, 152, 181, 182, 212, 213, 243, 244, 273, 274, 304, 305, 334, 335, 365];

  @override
  initState(){
    //TODO:: Load ad
    _ad = AdMobManager.createBannerAd(_isAdLoaded);
    _ad.load().then((value) => setState((){
      _isAdLoaded = true;
    }));
    print('from initstate insightss - rawPixels is ${widget.rawPixels}');

    if(widget.now.year%4 == 0){
      print('issa leap year :/');
      dateRanges = [1, 31, 32, 60, 61, 91, 92, 121, 122, 152, 153, 182, 183, 213, 214, 244, 245, 274, 275, 305, 306, 335, 336, 366];
    }
    widget.currentMonth = widget.now.month;
    startRange = dateRanges[(widget.currentMonth - 1) * 2];
    endRange = dateRanges[((widget.currentMonth - 1) * 2)+1];
    print('from initState insightss: startrange is $startRange, endRange is $endRange');
    super.initState();
  }

  @override
  void dispose() {
    _ad.dispose();

    super.dispose();
  }
  List<PixelDatum> getLineData(startRange, endRange, rawPixels)  {
    print('getLineData called!');
    List<PixelDatum> pixelLineData = [];
    var difference = endRange - startRange;
    var day = 1;
    for(var i= startRange; i<= endRange; i++){
      pixelLineData.add(new PixelDatum(day, rawPixels[i].intensity));
      day++;
      //print('from getLineData, i = $i :: added ${rawPixels[i].day}, ${rawPixels[i].intensity}');
    }
    //print('from getLineData, pixelLineData is $pixelLineData');
    return pixelLineData;
  }

  List<PixelDatum> getPieData(startRange, endRange, rawPixels){
    List<PixelDatum> pixelPieData = [];
    var pieValues = [0,0,0,0,0,0,0,0];
    var intensity = 0;
    for(var i = startRange; i <= endRange; i++){
      intensity = rawPixels[i].intensity;
      pieValues[intensity] ++;
      }

    for(var i = 1; i <=7; i++){
      //create new pie datum and add to list
      var pieDatum = new PixelDatum(i, pieValues[i]);
      pixelPieData.add(pieDatum);
    }
    return pixelPieData;
    }

  Widget getAverageMood(startRange, endRange, rawPixels){
    var totalMood = 0;
    var totalDays = 0;
    for(var i = startRange; i < endRange; i++){
      if (rawPixels[i].intensity != 0){
        totalMood+= rawPixels[i].intensity;
        totalDays++;
      }
    }
    var averageMood = totalMood/totalDays;
    return Text('Average Mood is $averageMood');
  }
  Widget getMoodVariation(startRange, endRange, rawPixels){
    List<int> listIntensities = [];
    for(var i = startRange; i < endRange; i++){
      listIntensities.add(rawPixels[i].intensity);
    }
    final standardDeviation = Stats.fromData(listIntensities).standardDeviation;
    return Text('Standard Deviation is $standardDeviation');
    }
  _getSeriesData(data) {

    List<charts.Series<PixelDatum, int>> series = [
      charts.Series(
          id: "Sales",
          data: data,
          domainFn: (PixelDatum series, _) => series.x,
          measureFn: (PixelDatum series, _) => series.y,
          //colorFn: (PixelDatum series, _) => charts.MaterialPalette.blue.shadeDefault
      )
    ];
    return series;
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
          child: Builder(
              builder: (context) {
                return BlocBuilder<PixelsBloc, PixelsState>(
                  builder: (_, state){
                    //wtf is going on lol
                    //print('from linechart - state is $state');
                    //print('from blocbuilder linechart - rawPixels is ${state.rawPixels}');


                    if(state.rawPixels != null) {
                      return ListView(
                          children:[


                            Container(
                              width: MediaQuery.of(context).size.width,
                              //height: 200,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: Colors.white),
                              padding: const EdgeInsets.all(20),
                              margin:  const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Text('Insights'),
                                  Container(
                                    height: MediaQuery.of(context).size.height/3,
                                    child:charts.LineChart(_getSeriesData(getLineData(startRange, endRange, state.rawPixels)), animate: true,)
                                  )
                                ]
                              ),
                            ),
                            Builder(
                                builder: (context){
                                  return BlocBuilder<UpdateSubscriptionBloc, UpdateSubscriptionState>(
                                      builder: (_, state){
                                        print('Premium subscription state from insights is ${state.isPremium}');
                                        if(state.isPremium){
                                          return Container(
                                              color: Colors.white,
                                              height: 200,
                                              width: 400,
                                              child: Text('Premium activated!')
                                          );
                                        } else return Container(height: 100, width: 320, child: _isAdLoaded ? AdWidget(ad: _ad) : Text('Ad not loaded :(') );
                                      }
                                  );
                                }
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              height: 200,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: Colors.white),
                              padding: const EdgeInsets.all(20),
                              margin:  const EdgeInsets.symmetric(vertical: 20),
                              child: charts.PieChart(_getSeriesData(getPieData(startRange, endRange, state.rawPixels)), animate: true),
                            ),

                            Container(
                                width: MediaQuery.of(context).size.width,
                              height: 200,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: Colors.white),
                              padding: const EdgeInsets.all(20),
                              margin:  const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  getAverageMood(startRange, endRange, state.rawPixels),
                                  getMoodVariation(startRange, endRange, state.rawPixels),
                                ]
                              )
                            ),

                          ]
                      );
                    } else return Text('rawPixels is null');
                  },
                );
              }
          ),
        )
    );
  }
}