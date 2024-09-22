import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import to handle weekdays and date formatting
import 'package:shimmer/shimmer.dart'; // Import the shimmer package

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
  String weatherIcon = '';
  double temperature = 0;
  double tempMax = 0;
  double tempMin = 0;
  double windSpeed = 0;
  int humidity = 0;
  String sunrise = '';
  String sunset = '';
  List<Map<String, dynamic>> forecastData = [];
  bool loading = true; // Initially set to true since we are fetching data

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
    print(
        'Location obtained: Latitude ${position.latitude}, Longitude ${position.longitude}');

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
          temperature =
              (weatherData['main']['temp'] as num).toDouble(); // Ensure double
          weatherDescription = weatherData['weather'][0]['description'];
          tempMax = (weatherData['main']['temp_max'] as num)
              .toDouble(); // Ensure double
          tempMin = (weatherData['main']['temp_min'] as num)
              .toDouble(); // Ensure double
          windSpeed =
              (weatherData['wind']['speed'] as num).toDouble(); // Ensure double
          humidity = weatherData['main']
              ['humidity']; // This is an int, so no need to convert

          // Get the icon from the current weather
          weatherIcon = weatherData['weather'][0]['icon'];

          // Get sunrise and sunset from the 'sys' object
          sunrise = _formatTime(weatherData['sys']['sunrise']);
          sunset = _formatTime(weatherData['sys']['sunset']);
          loading = false; // Set loading to false when data is ready
        });

        print('Current weather details updated in state.');
      } else {
        print(
            'Failed to fetch current weather data: HTTP status ${response.statusCode}');
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

        DateTime currentTime = DateTime.now();

        // Find the first forecast that's closest to the current time
        List forecastList = forecastDataRaw['list'];
        List<Map<String, dynamic>> filteredForecast = [];

        for (var entry in forecastList) {
          DateTime forecastTime =
              DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000);

          // Only add forecasts that are at or after the current time
          if (forecastTime.isAfter(currentTime)) {
            filteredForecast.add({
              'time': _formatTime(entry['dt']),
              'weekday': DateFormat('EEEE').format(forecastTime),
              'temp':
                  (entry['main']['temp'] as num).toDouble(), // Ensure double
              'icon': entry['weather'][0]['icon'], // Use icon for forecast
            });

            // Stop after collecting 5 intervals
            if (filteredForecast.length == 5) {
              break;
            }
          }
        }

        setState(() {
          forecastData = filteredForecast;
          loading = false; // Set loading to false when data is ready
        });

        print('Filtered forecast details updated in state.');
      } else {
        print(
            'Failed to fetch forecast data: HTTP status ${response.statusCode}');
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
        child: loading ? _buildSkeleton() : _buildWeatherContent(),
      ),
    );
  }

  // Add shimmer effect to the skeleton
  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Skeleton for city name
          Container(
            width: 200,
            height: 30,
            color: Colors.grey[300],
            margin: EdgeInsets.only(bottom: 10),
          ),
          // Skeleton for weather description
          Container(
            width: 150,
            height: 20,
            color: Colors.grey[300],
            margin: EdgeInsets.only(bottom: 20),
          ),
          // Skeleton for weather icon
          Container(
            width: 100,
            height: 100,
            color: Colors.grey[300],
            margin: EdgeInsets.only(bottom: 20),
          ),
          // Skeleton for temperature
          Container(
            width: 150,
            height: 50,
            color: Colors.grey[300],
            margin: EdgeInsets.only(bottom: 20),
          ),
          // Skeleton for Max/Min temperatures
          Container(
            width: 200,
            height: 20,
            color: Colors.grey[300],
            margin: EdgeInsets.only(bottom: 20),
          ),
          // Skeleton for wind speed, humidity, sunrise, sunset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHorizontalSkeletonBlock(),
              _buildVerticalDivider(),
              _buildHorizontalSkeletonBlock(),
              _buildVerticalDivider(),
              _buildHorizontalSkeletonBlock(),
              _buildVerticalDivider(),
              _buildHorizontalSkeletonBlock(),
            ],
          ),
          SizedBox(height: 20), // Add space before forecast
          // Skeleton for forecast icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (_) => _buildForecastSkeleton()),
          ),
        ],
      ),
    );
  }

// Helper to build skeleton block for wind speed, humidity, etc.
  Widget _buildHorizontalSkeletonBlock() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 20,
          color: Colors.grey[300],
          margin: EdgeInsets.only(bottom: 5),
        ),
        Container(
          width: 60,
          height: 20,
          color: Colors.grey[300],
        ),
      ],
    );
  }

// Helper to build a vertical divider between skeleton blocks
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey[400],
    );
  }

// Helper to build skeleton for forecast icons
  Widget _buildForecastSkeleton() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 20,
          color: Colors.grey[300],
          margin: EdgeInsets.only(bottom: 5),
        ),
        Container(
          width: 40,
          height: 50,
          color: Colors.grey[300],
          margin: EdgeInsets.only(bottom: 5),
        ),
        Container(
          width: 40,
          height: 20,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildWeatherContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        // City name
        Text(
          location,
          style: TextStyle(
            fontSize: 36, // Reduced font size
            fontWeight: FontWeight.w600, // Lighter than bold
            color: Colors.grey[800], // Dark gray instead of black
          ),
        ),
        // Weather description
        Text(
          weatherDescription.toUpperCase(),
          style: TextStyle(
            fontSize: 20, // Adjusted size
            fontWeight: FontWeight.w400, // Slightly lighter
            color: Colors.grey[800], // Dark gray instead of black
          ),
        ),
        Image.network(
          'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
          width: 100,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child; // Image has fully loaded, display it
            } else {
              return Container(
                width: 100,
                height: 100,
                color:
                    Colors.grey[300], // Display skeleton while image is loading
              );
            }
          },
        ),
        // Temperature
        Text(
          '${temperature.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 72, // Reduced font size
            fontWeight: FontWeight.w300, // Lighter than bold
            color: Colors.grey[800], // Dark gray instead of black
          ),
        ),
        Text(
          'Max: ${tempMax.toStringAsFixed(1)}°, Min: ${tempMin.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 16, // Adjusted size
            color: Colors.grey[800], // Dark gray
          ),
        ),
        SizedBox(height: 30),
        // Add this inside your build method where you display the wind speed, humidity, sunrise, and sunset.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text('Wind speed', style: TextStyle(color: Colors.grey[800])),
                Text('${windSpeed.toStringAsFixed(1)} km/h',
                    style: TextStyle(color: Colors.grey[800])),
              ],
            ),
            Container(
              height: 30, // Line height
              width: 1, // Line width
              color: Colors.grey, // Line color
            ),
            Column(
              children: [
                Text('Humidity', style: TextStyle(color: Colors.grey[800])),
                Text('${humidity.toString()}%',
                    style: TextStyle(color: Colors.grey[800])),
              ],
            ),
            Container(
              height: 30, // Line height
              width: 1, // Line width
              color: Colors.grey, // Line color
            ),
            Column(
              children: [
                Text('Sunrise', style: TextStyle(color: Colors.grey[800])),
                Text(sunrise, style: TextStyle(color: Colors.grey[800])),
              ],
            ),
            Container(
              height: 30, // Line height
              width: 1, // Line width
              color: Colors.grey, // Line color
            ),
            Column(
              children: [
                Text('Sunset', style: TextStyle(color: Colors.grey[800])),
                Text(sunset, style: TextStyle(color: Colors.grey[800])),
              ],
            ),
          ],
        ),
        SizedBox(height: 40),
        // Display 3-hour forecast with weekdays
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: forecastData.map((data) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0), // Added padding for better spacing
                child: Column(
                  children: [
                    Text(data['weekday'],
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800])), // Display weekday
                    Text(data['time'],
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[800])),
                    Image.network(
                        'https://openweathermap.org/img/wn/${data['icon']}@2x.png',
                        width: 50), // Display weather icon
                    Text('${data['temp'].toStringAsFixed(1)}°',
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[800])),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
