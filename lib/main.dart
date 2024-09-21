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
  String apiKey = 'bd18dc499b548b327f861fa74c665663';
  String location = 'Fetching location...';
  String weatherDescription = '';
  double temperature = 0;
  double tempMax = 0;
  double tempMin = 0;
  double windSpeed = 0;
  int humidity = 0;
  String sunrise = '';
  String sunset = '';

  @override
  void initState() {
    super.initState();
    print('Initializing state and starting location and weather fetch...');
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
      print('Location services are disabled.');
      return;
    }

    // Check for permission
    print('Checking location permission...');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = 'Location permission denied';
        });
        print('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        location = 'Location permissions are permanently denied.';
      });
      print('Location permissions are permanently denied.');
      return;
    }

    // Get current location
    print('Fetching current location...');
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print('Location obtained: Latitude ${position.latitude}, Longitude ${position.longitude}');
    _fetchWeather(position.latitude, position.longitude);
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    final String weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

    print('Fetching weather data from API...');
    print('API URL: $weatherUrl');
    try {
      final response = await http.get(Uri.parse(weatherUrl));
      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        print('Weather data received: $weatherData');

        setState(() {
          location = weatherData['name']; // City name
          temperature = weatherData['main']['temp'];
          weatherDescription = weatherData['weather'][0]['description'];
          tempMax = weatherData['main']['temp_max'];
          tempMin = weatherData['main']['temp_min'];
          windSpeed = weatherData['wind']['speed'];
          humidity = weatherData['main']['humidity'];
          
          // Get sunrise and sunset from the 'sys' object
          sunrise = _formatTime(weatherData['sys']['sunrise']);
          sunset = _formatTime(weatherData['sys']['sunset']);
        });

        print('Weather details updated in state.');
      } else {
        print('Failed to fetch weather data: HTTP status ${response.statusCode}');
        setState(() {
          location = 'Error fetching weather data';
        });
      }
    } catch (error) {
      print('Error fetching weather data: $error');
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
              'Weather Forecast!',
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
            Text('Wind speed: ${windSpeed.toStringAsFixed(1)} km/h', style: TextStyle(color: Colors.white)),
            Text('Humidity: ${humidity.toString()}%', style: TextStyle(color: Colors.white)),
            SizedBox(height: 20),
            // Display Sunrise and Sunset times
            Text('Sunrise: $sunrise', style: TextStyle(color: Colors.white)),
            Text('Sunset: $sunset', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
