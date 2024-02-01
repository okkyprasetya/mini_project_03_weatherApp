import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _weather = 'Loading...';
  String _city = '';
  String _latitude = '';
  String _longitude = '';
  String _iconURL='';

  @override
  void initState() {
    super.initState();
    _updateWeather();
  }

  Future<void> _updateWeather() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low
    );
    await _getCityName(position.latitude, position.longitude);

    final response = await http.get(Uri.parse(
        'http://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=c36d00a1ade6f97e5f7d9861c3dff92c'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String weather = data['weather'][0]['description'];
      String iconCode = data['weather'][0]['icon'];
      setState(() {
        _weather = weather.toTitleCase();
        _longitude = position.latitude.toString();
        _latitude = position.longitude.toString();
        _iconURL = 'http://openweathermap.org/img/w/$iconCode.png';
      });
    } else {
      setState(() {
        _weather = 'Failed to load weather data.';
      });
    }
  }

  Future<void> _getCityName(double latitude, double longitude) async {
    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String cityName = data['address']['city'] ??
          data['address']['town'] ??
          data['address']['village'] ??
          '';
      setState(() {
        _city = cityName;
      });
    } else {
      setState(() {
        _city = 'Failed to get city name.';
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Map Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Image.network('https://maps.googleapis.com/maps/api/staticmap?center=$_latitude,$_longitude&zoom=14&size=300x200&key='),
            SizedBox(height: 20),
            Text(
              'City',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${_city}'),
            SizedBox(height: 20),
            Card(
              child: ListTile(
                title: Text('Current Weather',style: TextStyle(fontWeight: FontWeight.bold),),
                subtitle: Text('${_weather}'),
                trailing:  _iconURL.isNotEmpty
                    ? Image.network(_iconURL, width: 50, height: 50)
                    : Text('Icon not available'),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text('Latitude :',style: TextStyle(fontWeight: FontWeight.bold),),
                subtitle: Text('${_latitude}'),
                trailing:  Icon(Icons.arrow_circle_up_outlined)
              ),
            ),
            SizedBox(height: 10,),
            Card(
              child: ListTile(
                  title: Text('Latitude :',style: TextStyle(fontWeight: FontWeight.bold),),
                  subtitle: Text('${_latitude}'),
                  trailing:  Icon(Icons.arrow_circle_left_outlined)
              ),
            ),

          ],
        ),
      ),
    );
  }
}
