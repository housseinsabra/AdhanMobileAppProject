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
  final String city;
  final String country;

  PrayerTimes({
    required this.timings,
    required this.date,
    required this.city,
    required this.country
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json, String city, String country) {
    return PrayerTimes(
      timings: Map<String, String>.from(json['data']['timings']),
      date: json['data']['date']['readable'],
      city: city,
      country: country,
    );
  }
}

// ========================================================================
// 2. THEME & APP ENTRY
// ========================================================================

class AdhanApp extends StatelessWidget {
  const AdhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adhan Prayer Times',
      theme: ThemeData(
        useMaterial3: true,
        // Islamic Color Palette
        scaffoldBackgroundColor: const Color(0xFFFDFCF5), // Cream/Parchment
        primaryColor: const Color(0xFF1B5E20), // Deep Emerald Green
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFD4AF37), // Gold
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1B5E20)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
        ),
      ),
      home: const PrayerTimesScreen(),
    );
  }
}

// ========================================================================
// 3. PRAYER TIMES SCREEN
// ========================================================================

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Future<PrayerTimes> _prayerTimesFuture;

  String _city = 'Mecca';
  String _country = 'SA';

  final TextEditingController _cityController = TextEditingController(text: 'Mecca');
  final TextEditingController _countryController = TextEditingController(text: 'SA');

  final Map<String, String> _prayerOrder = const {
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
    _prayerTimesFuture = _fetchPrayerTimes(_city, _country);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<PrayerTimes> _fetchPrayerTimes(String city, String country) async {
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final url = Uri.parse(
        'http://api.aladhan.com/v1/timingsByCity/$today?city=$city&country=$country&method=2');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'OK') {
        return PrayerTimes.fromJson(jsonResponse, city, country);
      } else {
        throw Exception('Location not found.');
      }
    } else {
      throw Exception('Failed to connect to API');
    }
  }

  void _setNewLocation() {
    final newCity = _cityController.text.trim();
    final newCountry = _countryController.text.trim();
    if (newCity.isNotEmpty && newCountry.isNotEmpty) {
      setState(() {
        _city = newCity;
        _country = newCountry;
        _prayerTimesFuture = _fetchPrayerTimes(_city, _country);
      });
      FocusScope.of(context).unfocus(); // Close keyboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both City and Country.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times', style: TextStyle(fontFamily: 'Serif', letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.mosque, color: Color(0xFFD4AF37)))
        ],
      ),
      // ⭐ FIX: Make the entire body scrollable
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ⭐️ AYAH HEADER ⭐️
            const AyahHeader(),

            // ⭐️ MAIN CONTENT (Padded section) ⭐️
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Location Input Section
                  _buildLocationForm(),

                  const SizedBox(height: 20),
                  const Divider(thickness: 1, color: Color(0xFFD4AF37)),
                  const SizedBox(height: 20),

                  // API Result Section
                  FutureBuilder<PrayerTimes>(
                    future: _prayerTimesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 50.0),
                          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                        );
                      } else if (snapshot.hasError) {
                        return _buildErrorState();
                      } else if (snapshot.hasData) {
                        return _buildPrayerList(snapshot.data!);
                      } else {
                        return const Text('Enter location');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLocationForm() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city, color: Color(0xFF1B5E20)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _countryController,
            decoration: const InputDecoration(
              labelText: 'Country',
              prefixIcon: Icon(Icons.flag, color: Color(0xFF1B5E20)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1)
          ),
          child: IconButton(
            onPressed: _setNewLocation,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerList(PrayerTimes data) {
    return Column(
      // We don't need ListView here as the parent is already a SingleChildScrollView
      children: [
        // Location Info
        Text(
          '${data.city}, ${data.country}',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              fontFamily: 'Serif'
          ),
        ),
        Text(
          data.date,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 20),

        // List of Cards
        ..._prayerOrder.entries.map((entry) {

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ]
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.access_time, color: Color(0xFFD4AF37)),
              title: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                ),
              ),
              trailing: Text(
                data.timings[entry.key] ?? 'N/A',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Monospace',
                    color: Colors.black87
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3))
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 10),
          Expanded(child: Text('Could not find location. Please try a major city.')),
        ],
      ),
    );
  }
}

// ========================================================================
// 4. CUSTOM ISLAMIC HEADER WIDGET
// ========================================================================

class AyahHeader extends StatelessWidget {
  const AyahHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20), // Dark Green
            Color(0xFF2E7D32), // Lighter Green
          ],
        ),
        // No rounded corners at top to merge with app bar, only bottom
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern (Optional subtle decoration)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.star, size: 150, color: Colors.white.withValues(alpha: 0.05)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            child: Column(
              children: [
                // Islamic Ornament Divider
                const Text(
                    '﷽',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24)
                ),
                const SizedBox(height: 10),

                // Arabic Ayah
                const Text(
                  'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif', // Use a standard serif font
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 10),

                // English Translation
                Text(
                  '"Indeed, prayer has been decreed upon the believers a decree of specified times."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Surah An-Nisa 4:103',
                  style: TextStyle(
                      color: Color(0xFFD4AF37), // Gold
                      fontSize: 12,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}