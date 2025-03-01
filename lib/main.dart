import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class OnlineMapScreen extends StatefulWidget {
  @override
  _OnlineMapScreenState createState() => _OnlineMapScreenState();
}

class _OnlineMapScreenState extends State<OnlineMapScreen> {
  late DateTime _sevenMinutesAgo;
  late MapController _mapController;
  bool _locationFetched = false;
  LatLng _currentLocation = LatLng(52.31511, 3.29251);
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _sevenMinutesAgo = DateTime.now().subtract(Duration(minutes: 11));
    _mapController = MapController();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Locatiediensten zijn uitgeschakeld.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Locatiepermissies zijn geweigerd');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Locatiepermissies zijn permanent geweigerd.');
    }

    _updateLocation();

    _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateLocation();
    });
  }

  void _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInDegrees = 0.00050;
      double newLatitude = position.latitude + distanceInDegrees;
      double newLongitude = position.longitude - distanceInDegrees;

      setState(() {
        _locationFetched = true;
        _currentLocation = LatLng(newLatitude, newLongitude);
        _mapController.move(_currentLocation, 18);
      });

      print("Locatie bijgewerkt naar: $_currentLocation");
    } catch (e) {
      print("Fout bij ophalen locatie: $e");
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('HH:mm').format(_sevenMinutesAgo);
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 350,
            width: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                if (_locationFetched)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 100.0,
                        height: 100.0,
                        point: LatLng(_currentLocation.latitude, _currentLocation.longitude),
                        child: Transform.translate(
                          offset: Offset(0, 35),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.4),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blueGrey.withOpacity(0.6), width: 2),
                            ),
                          ),
                        ),
                      ),
                      Marker(
                        width: 96.0,
                        height: 96.0,
                        point: _currentLocation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              bottom: 22,
                              height: 85,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: 60,
                              ),
                            ),
                            Positioned(
                              bottom: 45,
                              child: 
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 3),
                                  ),
                                ),),
                              Positioned(
                                bottom: 56,
                                child:
                                  Icon(Icons.phone_android_outlined, color: Colors.black, size: 30),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ),
              ],
            ),
          ),

          SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.phone_android, size: 40, color: Colors.blue),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Google Pixel 9 pro",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Laatst gezien: Vandaag $formattedTime",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 40),

          Column(
            children: [
              _buildButton(Icons.volume_up, "Geluid afspelen"),
              SizedBox(height: 10),
              _buildButton(Icons.lock_outline, "Apparaat beveiligen"),
              SizedBox(height: 10),
              _buildButton(Icons.report, "Markeren als kwijtgeraakt"),
              SizedBox(height: 10),
              _buildButton(Icons.share, "Apparaat delen"),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildButton(IconData icon, String text) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        // Actie bij klikken
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 20),
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
          SizedBox(width: 15),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}
}

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(MaterialApp(
    title: 'Apparaat vinden',
    theme: ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black),
      ),
    ),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
      ),
      primarySwatch: Colors.grey,
    ),
    themeMode: ThemeMode.system,
    home: OnlineMapScreen(),
  ));
}
