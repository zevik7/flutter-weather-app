import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(WeatherApp());

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String apiKey = '664b14a3ccc6ad01c1776f06cbde55ca';
  String location = 'Fetching location...';
  String weatherDescription = '';
  double temperature = 0;
  double tempMax = 0;
  double tempMin = 0;
  double windSpeed = 0;
  String sunrise = '';
  String sunset = '';
  int humidity = 0;
  List<dynamic> forecast = [];

  @override
  void initState() {
    super.initState();
    _getLocationAndWeather();
  }

  Future<void> _getLocationAndWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        location = 'Location services are disabled.';
      });
      return;
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        location = 'Location permissions are permanently denied.';
      });
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _fetchWeather(position.latitude, position.longitude);
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    final String weatherUrl =
        'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,alerts&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(weatherUrl));
      final weatherData = json.decode(response.body);

      setState(() {
        location = weatherData['timezone'];
        temperature = weatherData['current']['temp'];
        weatherDescription = weatherData['current']['weather'][0]['description'];
        tempMax = weatherData['daily'][0]['temp']['max'];
        tempMin = weatherData['daily'][0]['temp']['min'];
        windSpeed = weatherData['current']['wind_speed'];
        sunrise = _formatTime(weatherData['current']['sunrise']);
        sunset = _formatTime(weatherData['current']['sunset']);
        humidity = weatherData['current']['humidity'];
        forecast = weatherData['hourly'].sublist(0, 5); // Next 5 periods, 3 hours apart
      });
    } catch (error) {
      setState(() {
        location = 'Error fetching weather data';
      });
    }
  }

  String _formatTime(int timestamp) {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '5-day forecast!',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              location,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              weatherDescription.toUpperCase(),
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            Icon(Icons.cloud, size: 80, color: Colors.white),
            Text(
              '${temperature.toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text('Max: ${tempMax.toStringAsFixed(1)}°, Min: ${tempMin.toStringAsFixed(1)}°'),
            SizedBox(height: 20),
            // Forecast
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: forecast.map((data) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Icon(Icons.wb_sunny, color: Colors.white),
                        Text('${data['temp'].toStringAsFixed(1)}°', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            Text('Wind speed: ${windSpeed} km/h'),
            Text('Sunrise: $sunrise, Sunset: $sunset'),
            Text('Humidity: $humidity%'),
          ],
        ),
      ),
    );
  }
}
