import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const AdhanApp());
}

// ========================================================================
// 1. DATA MODEL
// ========================================================================

class PrayerTimes {
  final Map<String, String> timings;
  final String date;

  // Added location fields to the model for better display
  final String city;
  final String country;

  PrayerTimes({required this.timings, required this.date, required this.city, required this.country});

  factory PrayerTimes.fromJson(Map<String, dynamic> json, String city, String country) {
    return PrayerTimes(
      timings: Map<String, String>.from(json['data']['timings']),
      date: json['data']['date']['readable'],
      city: city,
      country: country,
    );
  }
}

// (AdhanApp StatelessWidget remains the same)
class AdhanApp extends StatelessWidget {
  const AdhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adhan Prayer Times',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const PrayerTimesScreen(),
    );
  }
}

// ========================================================================
// 3. PRAYER TIMES SCREEN (Updated State)
// ========================================================================

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  // Use a Future to hold the API request result (will be initialized later)
  late Future<PrayerTimes> _prayerTimesFuture;

  // Location State Variables (Editable)
  String _city = 'London'; // Default city
  String _country = 'UK';  // Default country

  final TextEditingController _cityController = TextEditingController(text: 'London');
  final TextEditingController _countryController = TextEditingController(text: 'UK');

  // Custom list to control the order and display names of prayers
  final Map<String, String> _prayerOrder = {
    'Fajr': 'Fajr',
    'Sunrise': 'Sunrise',
    'Dhuhr': 'Dhuhr',
    'Asr': 'Asr',
    'Maghrib': 'Maghrib',
    'Isha': 'Isha',
  };

  @override
  void initState() {
    super.initState();
    // Initialize the future with the default location
    _prayerTimesFuture = _fetchPrayerTimes(_city, _country);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // CORE: API Call to Aladhan (Now accepts dynamic city/country)
  Future<PrayerTimes> _fetchPrayerTimes(String city, String country) async {
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());

    // IMPORTANT: URL now uses the provided city and country strings
    final url = Uri.parse(
        'http://api.aladhan.com/v1/timingsByCity/$today?city=$city&country=$country&method=2');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'OK') {
        // Pass the requested city and country to the factory constructor
        return PrayerTimes.fromJson(jsonResponse, city, country);
      } else {
        throw Exception('Location not found or invalid API response.');
      }
    } else {
      throw Exception('Failed to connect to API: ${response.statusCode}');
    }
  }

  // New function to handle user input and refresh the future
  void _setNewLocation() {
    // Get trimmed values from controllers
    final newCity = _cityController.text.trim();
    final newCountry = _countryController.text.trim();

    // Only update if both fields are non-empty
    if (newCity.isNotEmpty && newCountry.isNotEmpty) {
      setState(() {
        _city = newCity;
        _country = newCountry;
        // Reassign the Future to trigger a refresh/new API call
        _prayerTimesFuture = _fetchPrayerTimes(_city, _country);
      });
    } else {
      // Optional: Show a snackbar or alert if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both City and Country.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adhan Prayer Times'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ⭐️ LOCATION INPUT FORM ⭐️
            Container(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _setNewLocation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // ⭐️ PRAYER TIMES DISPLAY ⭐️
            Expanded(
              child: FutureBuilder<PrayerTimes>(
                future: _prayerTimesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // Show a helpful error message if the location is bad
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Could not find times for $_city, $_country. Please check the spelling or try a major city.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final prayerData = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Location Header
                        Card(
                          elevation: 4,
                          color: Theme.of(context).primaryColor.withAlpha(25), // FIX: Replaced withOpacity(0.1)
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text('${prayerData.city}, ${prayerData.country}',
                                    style: const TextStyle(
                                        fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: ${prayerData.date}',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Prayer Times List
                        Expanded(
                          child: ListView(
                            children: _prayerOrder.entries.map((entry) {
                              final prayerName = entry.key;
                              final time = prayerData.timings[prayerName] ?? 'N/A';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 2,
                                child: ListTile(
                                  leading: const Icon(Icons.access_time_filled, color: Colors.teal),
                                  title: Text(
                                    prayerName,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  trailing: Text(
                                    time,
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: Text('Enter a city and country to view times.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}