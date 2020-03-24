import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapstore/login.dart';
import 'package:mapstore/models/dataShop.dart';
import 'package:http/http.dart' as http;
import 'package:mapstore/search.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'models/dataLogin.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Circle> _circles = HashSet<Circle>();
  static double x = 0.0;
  static double y = 0.0;
  static var nameLogin = null;
  static double distant = 600;
  double zoomVal = 16;
  BitmapDescriptor _markerIcon;
  BitmapDescriptor _markerIconMe;
  Set<Marker> _markers = HashSet<Marker>();

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  List<DataShop> datashop;
  List<DataLogin> dataLogin;

  @override
  void initState() {
    super.initState();
    iniPlatformState();
    _setMarkerIcon();
  }

  Future<void> iniPlatformState() async {
    print("==============object==========");
    datashop = null;
    var response = await http.get(
        Uri.encodeFull("http://206.189.46.191/WebAPI/shopAll"),
        headers: {"Accept": "application/json"});
    datashop = dataShopFromJson(response.body);
    print("data_shop : " + datashop.length.toString());
    setState(() {});

    var currentLocation = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    x = currentLocation.latitude;
    y = currentLocation.longitude;
    _setCircles(x, y);
    // ร้าน
    if (datashop.length > 0) {
      for (var i = 0; i < datashop.length; i++) {
        final MarkerId markerId = MarkerId(i.toString());
        double x1 = double.parse(datashop[i].shopsLatitube);
        double y1 = double.parse(datashop[i].shopsLongtitube);
        double distans1 = await Geolocator().distanceBetween(x, y, x1, y1);
        print("distans1 : " +
            datashop[i].shopsName +
            " : " +
            distans1.toString());
        if (distans1 < distant) {
          final Marker marker = Marker(
            markerId: markerId,
            position: LatLng(
              double.parse(datashop[i].shopsLatitube),
              double.parse(datashop[i].shopsLongtitube),
            ),
            infoWindow: InfoWindow(
                title: datashop[i].shopsName,
                snippet: datashop[i].shopsAddress,
                onTap: () {
                  print(markers[markerId].markerId.value);
                  showModalBottomSheet(
                      context: context,
                      builder: (builder) {
                        return Container(
                          child: _buildBottonNavigationMethod(
                              markers[markerId].markerId.value),
                        );
                      });
                }),
            icon: _markerIcon,
          );
          markers[markerId] = marker;
        }
      }
    }
    setState(() {});
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(x, y),
    zoom: 16,
  );

  void _setCircles(x, y) {
    _circles.clear();
    _circles.add(
      Circle(
          circleId: CircleId("0"),
          center: LatLng(x, y),
          radius: distant,
          strokeWidth: 2,
          fillColor: Color.fromRGBO(102, 51, 153, .5)),
    );
  }

  void _setMarkerIcon() async {
    _markerIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/store.png');
    _markerIconMe = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/pin.png');
  }

  // รับค่าLogin
  _navigateAndDisplaySelection(BuildContext context) async {
    var userLogin = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PageLogin()),
    );
    dataLogin = userLogin;
  }

  // รับค่าค้นหา
  _navigateSearch(BuildContext context) async {
    // var dataSearch = await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => PageSearch()),
    // );
    // dataLogin = userLogin;
  }

  _alertComment() {
    Alert(
      context: context,
      type: AlertType.info,
      title: "กรุณาเข้าสู่ระบบ",
      desc: "",
      buttons: [
        DialogButton(
          child: Text(
            "ตกลก",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () async {
            Navigator.pop(context);
            var userLogin = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PageLogin()),
            );
            dataLogin = userLogin;
          },
          width: 120,
        )
      ],
    ).show();
  }

  _alertInput() {
    Alert(
        context: context,
        title: "แสดงความคิดเห็น",
        content: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.account_circle),
                labelText: 'Username',
              ),
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                icon: Icon(Icons.lock),
                labelText: 'Password',
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "LOGIN",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  Future<void> _goToTheLake() async {
    iniPlatformState();
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
  }

  Widget _zoomminusfunction() {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
          icon: Icon(FontAwesomeIcons.searchMinus, color: Colors.white),
          onPressed: () {
            zoomVal--;
            _minus(zoomVal);
          }),
    );
  }

  Widget _zoomplusfunction() {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
          icon: Icon(FontAwesomeIcons.searchPlus, color: Colors.white),
          onPressed: () {
            zoomVal++;
            _plus(zoomVal);
          }),
    );
  }

  Future<void> _minus(double zoomVal) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(x, y), zoom: zoomVal)));
  }

  Future<void> _plus(double zoomVal) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(x, y), zoom: zoomVal)));
  }

  Container _buildBottonNavigationMethod(var index) {
    int i = int.parse(index);
    return Container(
      child: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 300.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/image.png'), fit: BoxFit.fill),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(datashop[i].shopsName,
                    style: TextStyle(
                      fontSize: 25.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 10.0),
                Row(
                  children: <Widget>[
                    Text(
                      '4.9',
                      style: TextStyle(color: Colors.grey, fontSize: 17.0),
                    ),
                    SizedBox(width: 10.0),
                    Icon(Icons.star, color: Color(0xFF3d9af9), size: 16.0),
                    Icon(Icons.star, color: Color(0xFF3d9af9), size: 16.0),
                    Icon(Icons.star, color: Color(0xFF3d9af9), size: 16.0),
                    Icon(Icons.star, color: Color(0xFF3d9af9), size: 16.0),
                    Icon(Icons.star, color: Color(0xFF3d9af9), size: 16.0),
                  ],
                ),
                SizedBox(height: 15.0),
                Text(datashop[i].shopsType,
                    style: TextStyle(fontSize: 16.0, color: Colors.black)),
                SizedBox(height: 15.0),
                Container(
                  child: Text(
                    datashop[i].shopsAddress,
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 15.0),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  width: double.infinity,
                  height: 50.0,
                  child: RaisedButton(
                    elevation: 5.0,
                    padding: EdgeInsets.all(15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    onPressed: () {
                      if (dataLogin == null) {
                        _alertComment();
                      } else {
                        _alertInput();
                      }
                    },
                    color: Color(0xFF3d9af9),
                    child: Text(
                      'แสดงความคิดเห็น',
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15.0),
                Container(
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        Card(
                            child: Container(
                          padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                          width: 200,
                          height: 100,
                          child: Column(
                            children: <Widget>[
                              Text(
                                'แบงค์',
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              ),
                              SizedBox(height: 10.0),
                              Text("ร้านดีครับ"),
                              SizedBox(height: 10.0),
                              _buildRatingStars(int.parse("4")),
                              SizedBox(height: 10.0),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Text _buildRatingStars(int rating) {
    String stars = '';
    for (int i = 0; i < rating; i++) {
      stars += '⭐ ';
    }
    stars.trim();
    return Text(stars);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        leading: (dataLogin != null)
            ? IconButton(icon: Icon(FontAwesomeIcons.addressBook))
            : IconButton(
                icon: Icon(FontAwesomeIcons.user),
                onPressed: () => _navigateAndDisplaySelection(context)),
        title: Text("Map Store"),
        actions: <Widget>[
          _zoomminusfunction(),
          _zoomplusfunction(),
        ],
      ),
      body: Stack(
        children: <Widget>[
          (x != 0.0 && y != 0.0)
              ? GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  circles: _circles,
                  // myLocationEnabled: true,
                  // myLocationButtonEnabled: true,
                  // markers: {
                  //   newyork1Marker,
                  // },
                  markers: Set<Marker>.of(markers.values),
                )
              : Container(
                  child: SpinKitFadingCircle(
                    color: Colors.cyan,
                    size: 50.0,
                  ),
                ),
          Container(
            padding: EdgeInsets.all(20),
            child: Stack(
              children: <Widget>[
                Align(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          height: 40,
                          child: RaisedButton(
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 2,
                                ),
                                Text(
                                  "ค้นหา",
                                  style: TextStyle(color: Colors.white),
                                )
                              ],
                            ),
                            color: Color(0xFF3d9af9),
                            onPressed: () => _navigateSearch(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(18.0),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                )),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: Text('ฉัน'),
        icon: Icon(Icons.location_searching),
      ),
    );
  }
}
