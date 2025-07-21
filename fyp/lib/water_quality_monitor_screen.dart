import 'package:flutter/material.dart';
import 'package:fyp/NotificationManager.dart';
import 'dart:io';
import 'dart:math';
import 'report_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'app_drawer.dart';
import 'notificationHelper.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';

class WaterQualityMonitorScreen extends StatefulWidget {
  const WaterQualityMonitorScreen({super.key});

  @override
  State<WaterQualityMonitorScreen> createState() =>
      _WaterQualityMonitorScreenState();
}

class _WaterQualityMonitorScreenState extends State<WaterQualityMonitorScreen> {
  bool _phAlertShown = false;
  bool _turbidityAlertShown = false;
  bool _temperatureAlertShown = false;
  bool _tdsAlertShown = false;
  bool _hardnessAlertShown = false;
  bool _conductivityAlertShown = false;
  bool _OxygenDissolvedAlertShown = false;
  double phLevel = 0;
  double turbidity = 0;
  double temperature = 0;
  double tds = 0;
  double hardness = 0;
  double conductivity = 0;
  double OxygenDissolved = 0;

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('sensors'); // ✅ Fixed path

  // Add state variables for model output
  int? contaminated;
  List<String> diseases = [];

  @override
  void initState() {
    super.initState();
    NotificationHelper.initializeNotifications();
    NotificationHelper.showNotification(
        "App Loaded", "Welcome to Water Quality Monitor!");
    _fetchData();
    _listenModelOutput(); // <-- Listen to model output
  }

  void _listenModelOutput() {
    final modelOutputRef = FirebaseDatabase.instance.ref('model_output');
    modelOutputRef.onValue.listen((DatabaseEvent event) {
      setState(() {
        // Instantly check turbidity range and update contamination status
        if (turbidity < 1800 || turbidity > 2500) {
          final data = event.snapshot.value as Map?;
          final bool? isContaminated =
              data != null ? data['contaminated'] as bool? : null;
          contaminated =
              isContaminated != null ? (isContaminated ? 1 : 0) : null;
          diseases = data != null && data['diseases'] != null
              ? List<String>.from(data['diseases'])
              : [];
        } else {
          // If turbidity is in safe range, immediately show no contamination
          contaminated = 0;
          diseases = [];
        }
      });
    });
  }

  double _calculateDissolvedOxygen(
      double tempC, double tdsMgL, double turbidityNTU) {
    // Weiss equation for DO saturation
    final tempK = tempC + 273.15;
    final lnDoSat = -139.34411 +
        (1.575701e5 / tempK) -
        (6.642308e7 / pow(tempK, 2)) +
        (1.243800e10 / pow(tempK, 3)) -
        (8.621949e11 / pow(tempK, 4));

    final doSat = exp(lnDoSat); // DO saturation in mg/L

    // Apply TDS correction
    final doTdsCorrected = doSat * (1 - tdsMgL / 1e6);

    // Apply turbidity adjustment (empirical factor)
    const kTurbidity = 0.00004; // Calibration constant
    final doFinal = doTdsCorrected * (1 - kTurbidity * turbidityNTU);

    return doFinal;
  }

  void _fetchData() async {
    _dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map;

      setState(() {
        turbidity = double.tryParse(data['turbidity']?.toString() ?? '') ?? 0;
        temperature =
            double.tryParse(data['temperature']?.toString() ?? '') ?? 0;
        tds = double.tryParse(data['tds']?.toString() ?? '') ?? 0;
        hardness = tds * 0.3;
        conductivity = tds * 0.64;
        OxygenDissolved =
            _calculateDissolvedOxygen(temperature, tds, turbidity);
      });

      // Update contamination status immediately when turbidity changes
      if (turbidity >= 1800 && turbidity <= 2500) {
        setState(() {
          contaminated = 0;
          diseases = [];
        });
      }

      _checkWaterQuality();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await _showExitDialog(context);
        if (exitApp) {
          exit(0); // Close the app
        }
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/logo1.jpg'),
                radius: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Hydrofy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 1.2,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: AppDrawer(),
        body: Stack(
          children: [
            // Modern gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade900.withOpacity(0.9),
                    Colors.blue.shade400.withOpacity(0.8),
                    Colors.cyan.shade200.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildGlassCard('Turbidity', '$turbidity NTU',
                            Icons.opacity, _checkTurbidity(turbidity)),
                        _buildGlassCard('Temperature', '$temperature°C',
                            Icons.thermostat, _checkTemperature(temperature)),
                        _buildGlassCard(
                            'TDS', '$tds ppm', Icons.liquor, _checkTDS(tds)),
                        _buildGlassCard('Hardness', '$hardness mg/L',
                            Icons.build, _checkHardness(hardness)),
                        _buildGlassCard('Conductivity', '$conductivity µS/cm',
                            Icons.flash_on, _checkConductivity(conductivity)),
                        _buildGlassCard(
                            'Dissolved Oxygen',
                            '${OxygenDissolved.toStringAsFixed(2)} mg/L',
                            Icons.air,
                            _checkOxygenDissolved(OxygenDissolved)),
                        const SizedBox(height: 20),
                        if (contaminated != null)
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            child: Card(
                              color: contaminated == 1
                                  ? Colors.red.withOpacity(0.7)
                                  : Colors.green.withOpacity(0.7),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: ListTile(
                                leading: Icon(
                                  contaminated == 1
                                      ? Icons.warning_amber_rounded
                                      : Icons.verified,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                title: Text(
                                  contaminated == 1
                                      ? 'Contaminated'
                                      : 'Not Contaminated',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                subtitle: contaminated == 1 &&
                                        diseases.isNotEmpty
                                    ? Text(
                                        'Possible Diseases: ${diseases.join(", ")}',
                                        style: TextStyle(color: Colors.white70),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Floating glassmorphic action bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.white.withOpacity(0.15),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNavButton(context, Icons.insert_chart,
                                  'Reports', ReportScreen()),
                              _buildNavButton(context, Icons.history, 'History',
                                  HistoryScreen()),
                              _buildNavButton(context, Icons.settings,
                                  'Settings', SettingsScreen()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkWaterQuality() {
    if (!_checkTurbidity(turbidity)) {
      if (!_turbidityAlertShown) {
        _notifyUser(
            "Turbidity Alert", "High turbidity detected: $turbidity NTU");
        _turbidityAlertShown = true;
      }
    } else {
      _turbidityAlertShown = false;
    }

    if (!_checkTemperature(temperature)) {
      if (!_temperatureAlertShown) {
        _notifyUser("Temperature Alert",
            "Abnormal temperature detected: $temperature°C");
        _temperatureAlertShown = true;
      }
    } else {
      _temperatureAlertShown = false;
    }

    if (!_checkTDS(tds)) {
      if (!_tdsAlertShown) {
        _notifyUser("TDS Alert", "TDS level is out of range: $tds mg/L");
        _tdsAlertShown = true;
      }
    } else {
      _tdsAlertShown = false;
    }

    if (!_checkHardness(hardness)) {
      if (!_hardnessAlertShown) {
        _notifyUser(
            "Hardness Alert", "Hardness level is out of range: $hardness mg/L");
        _hardnessAlertShown = true;
      }
    } else {
      _hardnessAlertShown = false;
    }

    if (!_checkConductivity(conductivity)) {
      if (!_conductivityAlertShown) {
        _notifyUser("Conductivity Alert",
            "Conductivity level is out of range: $conductivity µS/cm");
        _conductivityAlertShown = true;
      }
    } else {
      _conductivityAlertShown = false;
    }

    if (!_checkOxygenDissolved(OxygenDissolved)) {
      if (!_OxygenDissolvedAlertShown) {
        _notifyUser("Dissolved Oxygen Alert",
            "Dissolved Oxygen level is out of range: $OxygenDissolved mg/L");
        _OxygenDissolvedAlertShown = true;
      }
    } else {
      _OxygenDissolvedAlertShown = false;
    }
  }

  void _notifyUser(String title, String body) {
    NotificationManager().addNotification(title, body);
    NotificationHelper.showNotification(title, body);
  }

  bool _checkTurbidity(double value) => value >= 1800 && value <= 2500;

  bool _checkTemperature(double value) => value >= 10 && value <= 25;

  bool _checkTDS(double value) => value >= 0 && value <= 500;

  bool _checkHardness(double value) => value >= 80 && value <= 100;

  bool _checkConductivity(double value) => value >= 0 && value <= 500;

  bool _checkOxygenDissolved(double value) => value >= 6 && value <= 10;

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Do you really want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Do not exit
                  },
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Exit
                  },
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildGlassCard(
      String title, String value, IconData icon, bool status) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(icon, color: Colors.white),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                value,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
      BuildContext context, IconData icon, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
