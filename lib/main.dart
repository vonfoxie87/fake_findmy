import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OnlineMapScreen extends StatefulWidget {
  @override
  _OnlineMapScreenState createState() => _OnlineMapScreenState();
}

class _OnlineMapScreenState extends State<OnlineMapScreen> {
  late DateTime _sevenMinutesAgo;
  late MapController _mapController;
  bool _locationFetched = false;
  LatLng _currentLocation = LatLng(52.0026493, 4.3527631);
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _sevenMinutesAgo = DateTime.now().subtract(Duration(minutes: 7));
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

      double distanceInDegrees = 0.00100;
      double newLatitude = position.latitude + distanceInDegrees;
      double newLongitude = position.longitude - distanceInDegrees;

      setState(() {
        _locationFetched = true;
        _currentLocation = LatLng(newLatitude, newLongitude);
        _mapController.move(_currentLocation, 19);
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
    String formattedTime = DateFormat('dd-MM-yyyy HH:mm').format(_sevenMinutesAgo);
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
                        width: 80.0,
                        height: 80.0,
                        point: _currentLocation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pin-icoon achter de andere widgets
                            Positioned(
                              bottom: -11, // Onder de cirkel plaatsen
                              height: 85,
                              child: Icon(
                                Icons.location_on, // Pin-icoon van Material Icons
                                color: Colors.black, // Kleur van het pin-icoon
                                size: 60, // Grootte van het pin-icoon
                              ),
                            ),
                            Container(
                              width: 50, // Groter dan het icoon
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(1), // Blauwe cirkel met transparantie
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 3), // Blauwe rand
                              ),
                            ),
                            Icon(Icons.phone_android_outlined, color: Colors.black, size: 30),
                          ],
                        ),
                      ),
                    ]

                    
                  ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Telefoon icoon + tekst
          Container(
            width: double.infinity, // Volledige breedte
            padding: EdgeInsets.symmetric(horizontal: 20), // Optionele padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // Links uitlijnen
              children: [
                Icon(Icons.phone_android, size: 40, color: Colors.blue),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Teksten links uitlijnen
                  children: [
                    Text(
                      "Google Pixel 9 pro",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Laatst gezien: $formattedTime",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 40),

          // Drie knoppen onder elkaar
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
    width: double.infinity, // Volledige breedte
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(

        padding: EdgeInsets.symmetric(vertical: 15), // Ruimte binnen de knop
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Mooie afgeronde hoeken
        ),
      ),
      onPressed: () {
        // Actie bij klikken
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Zorgt dat alles links staat
        children: [
          SizedBox(width: 20), // Ruimte tussen icoon en tekst
          Icon(icon,  size: 20), // Icoon aan de linkerkant
          SizedBox(width: 15), // Ruimte tussen icoon en tekst
          Text(
            text,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
}

void main() {
  runApp(MaterialApp(
    title: 'Online Map',
    theme: ThemeData(
      brightness: Brightness.light,  // Lichte modus
      primarySwatch: Colors.blue,
    ),
    darkTheme: ThemeData(
      brightness: Brightness.dark,  // Donkere modus
      primarySwatch: Colors.grey,  // Je kunt een andere kleur kiezen voor donker thema
    ),
    themeMode: ThemeMode.system,  // Schakelt automatisch tussen licht en donker afhankelijk van systeeminstellingen
    home: OnlineMapScreen(),
  ));
}
