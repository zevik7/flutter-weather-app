import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import to handle weekdays and date formatting

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
  List<Map<String, dynamic>> forecastData = [];

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
    
    // Temporarily use hardcoded values for testing
    double lat = 10.036111;
    double lon = 105.787222;
    
    // Skip fetching the device's actual location and use the test values
    print('Using hardcoded test location: Latitude $lat, Longitude $lon');
    
    // Fetch both current weather and forecast using the hardcoded values
    _fetchCurrentWeather(lat, lon);
    _fetchForecastWeather(lat, lon);
  }

  // Fetch current weather using the /weather API
  Future<void> _fetchCurrentWeather(double lat, double lon) async {
    final String weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

    print('Fetching current weather data from API...');
    print('API URL: $weatherUrl');
    try {
      final response = await http.get(Uri.parse(weatherUrl));
      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        print('Current weather data received: $weatherData');

        setState(() {
          location = weatherData['name']; // City name
          temperature = (weatherData['main']['temp'] as num).toDouble(); // Ensure double
          weatherDescription = weatherData['weather'][0]['description'];
          tempMax = (weatherData['main']['temp_max'] as num).toDouble(); // Ensure double
          tempMin = (weatherData['main']['temp_min'] as num).toDouble(); // Ensure double
          windSpeed = (weatherData['wind']['speed'] as num).toDouble(); // Ensure double
          humidity = weatherData['main']['humidity']; // This is an int, so no need to convert
          
          // Get sunrise and sunset from the 'sys' object
          sunrise = _formatTime(weatherData['sys']['sunrise']);
          sunset = _formatTime(weatherData['sys']['sunset']);
        });

        print('Current weather details updated in state.');
      } else {
        print('Failed to fetch current weather data: HTTP status ${response.statusCode}');
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

  // Fetch 3-hour forecast using the /forecast API
  Future<void> _fetchForecastWeather(double lat, double lon) async {
    final String forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

    print('Fetching forecast data from API...');
    print('API URL: $forecastUrl');
    try {
      final response = await http.get(Uri.parse(forecastUrl));
      if (response.statusCode == 200) {
        final forecastDataRaw = json.decode(response.body);
        print('Forecast data received: $forecastDataRaw');

        setState(() {
          forecastData = forecastDataRaw['list'].take(5).map<Map<String, dynamic>>((entry) {
            return {
              'time': _formatTime(entry['dt']),
              'weekday': DateFormat('EEEE').format(DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000)),
              'temp': (entry['main']['temp'] as num).toDouble(), // Ensure double
              'icon': entry['weather'][0]['icon'], // Use icon for forecast
            };
          }).toList();
        });

        print('Forecast details updated in state.');
      } else {
        print('Failed to fetch forecast data: HTTP status ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching forecast data: $error');
    }
  }

  String _formatTime(int timestamp) {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Weather App',
              style: TextStyle(fontSize: 28.8, color: Colors.lightBlue), // Increased font size by 20%
            ),
            SizedBox(height: 20),
            Text(
              location,
              style: TextStyle(fontSize: 38.4, fontWeight: FontWeight.bold, color: Colors.black), // Increased font size by 20%
            ),
            Text(
              weatherDescription.toUpperCase(),
              style: TextStyle(fontSize: 24, color: Colors.black), // Increased font size by 20%
            ),
            Icon(Icons.cloud, size: 96, color: Colors.black), // Increased icon size by 20%
            Text(
              '${temperature.toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 76.8, fontWeight: FontWeight.bold, color: Colors.black), // Increased font size by 20%
            ),
            Text('Max: ${tempMax.toStringAsFixed(1)}°, Min: ${tempMin.toStringAsFixed(1)}°', style: TextStyle(color: Colors.black)),
            SizedBox(height: 20),
            Text('Wind speed: ${windSpeed.toStringAsFixed(1)} km/h', style: TextStyle(color: Colors.black)),
            Text('Humidity: ${humidity.toString()}%', style: TextStyle(color: Colors.black)),
            SizedBox(height: 20),
            Text('Sunrise: $sunrise', style: TextStyle(color: Colors.black)),
            Text('Sunset: $sunset', style: TextStyle(color: Colors.black)),
            SizedBox(height: 20),
            // Display 3-hour forecast with weekdays
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: forecastData.map((data) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added padding for better spacing
                    child: Column(
                      children: [
                        Text(data['weekday'], style: TextStyle(fontSize: 16, color: Colors.black)), // Display weekday
                        Text(data['time'], style: TextStyle(fontSize: 16, color: Colors.black)),
                        Image.network('https://openweathermap.org/img/wn/${data['icon']}@2x.png', width: 50), // Display weather icon
                        Text('${data['temp'].toStringAsFixed(1)}°', style: TextStyle(fontSize: 16, color: Colors.black)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
