import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'app_colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'water_quality_monitor_screen.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Map<String, dynamic>? _latestReport;
  bool _loading = false;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _generateReport() async {
    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to generate reports')),
        );
        return;
      }

      final sensorsSnap = await _dbRef.child('sensors').get();
      final sensors = sensorsSnap.value as Map?;

      if (sensors == null) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to fetch sensor data for report')),
        );
        return;
      }

      // Prepare input for model
      final input = {
        'Turbidity_NTU':
            double.tryParse(sensors['turbidity']?.toString() ?? '') ?? 0,
        'Temp_C':
            double.tryParse(sensors['temperature']?.toString() ?? '') ?? 0,
        'TDS_mgL': double.tryParse(sensors['tds']?.toString() ?? '') ?? 0,
        'Hardness_mgL':
            (double.tryParse(sensors['tds']?.toString() ?? '') ?? 0) * 0.3,
        'Conductivity_uS_cm':
            (double.tryParse(sensors['tds']?.toString() ?? '') ?? 0) * 0.64,
        'DO_mgL': _calculateDO(
          double.tryParse(sensors['temperature']?.toString() ?? '') ?? 0,
          double.tryParse(sensors['tds']?.toString() ?? '') ?? 0,
          double.tryParse(sensors['turbidity']?.toString() ?? '') ?? 0,
        ),
      };

      // Call Vercel API for contamination
      final contamResult = await ApiService.predictContamination(input);
      Map<String, dynamic> model =
          contamResult ?? {'contaminated': false, 'diseases': []};

      // If contaminated, call disease prediction
      if (model['is_contaminated'] == true) {
        final diseaseResult = await ApiService.predictDisease(input);
        if (diseaseResult != null && diseaseResult['diseases'] != null) {
          model['diseases'] = diseaseResult['diseases'];
        }
      } else {
        model['diseases'] = [];
      }
      model['contaminated'] = model['is_contaminated'] ?? false;

      final now = DateTime.now();
      final report = {
        'timestamp': now.toIso8601String(),
        'readable_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
        'sensors': sensors,
        'model_output': model,
        'user_id': user.uid,
        'user_email': user.email,
      };

      // Store report under user's reports
      await _dbRef.child('user_reports').child(user.uid).push().set(report);

      setState(() {
        _latestReport = report;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated and saved!')),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  double _calculateDO(double tempC, double tdsMgL, double turbidityNTU) {
    final tempK = tempC + 273.15;
    final lnDoSat = -139.34411 +
        (1.575701e5 / tempK) -
        (6.642308e7 / (tempK * tempK)) +
        (1.2438e10 / (tempK * tempK * tempK)) -
        (8.621949e11 / (tempK * tempK * tempK * tempK));
    final doSat = exp(lnDoSat);
    final doTdsCorrected = doSat * (1 - tdsMgL / 1e6);
    const kTurbidity = 0.005;
    final doFinal = doTdsCorrected * (1 - kTurbidity * turbidityNTU);
    return doFinal;
  }

  Widget _buildReportView(Map<String, dynamic> report) {
    final sensors = report['sensors'] as Map<dynamic, dynamic>?;
    final model = report['model_output'] as Map<dynamic, dynamic>?;
    final turbidity =
        double.tryParse(sensors?['turbidity']?.toString() ?? '') ?? 0;

    // Determine contamination status based on turbidity
    final bool isTurbiditySafe = turbidity >= 1800 && turbidity <= 2500;
    final Map<dynamic, dynamic> displayModel =
        isTurbiditySafe ? {'contaminated': false, 'diseases': []} : model ?? {};

    // Ensure contaminated is a boolean
    if (displayModel.containsKey('contaminated')) {
      final dynamic contaminated = displayModel['contaminated'];
      displayModel['contaminated'] = contaminated == true || contaminated == 1;
    }

    final bool contaminated = displayModel['contaminated'] == true;
    final List<dynamic> diseases =
        displayModel['diseases'] is List ? displayModel['diseases'] : [];

    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: contaminated
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.greenAccent.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: contaminated
                      ? Colors.redAccent.withOpacity(0.08)
                      : Colors.greenAccent.withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: contaminated
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        child: Icon(
                          contaminated
                              ? Icons.warning_amber_rounded
                              : Icons.verified,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        contaminated ? 'Contaminated' : 'Not Contaminated',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: contaminated
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Report Time: ${report['readable_time']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('Sensor Readings:',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white70)),
                  ...?sensors?.entries.map((e) => Text('${e.key}: ${e.value}',
                      style: TextStyle(color: Colors.white70))),
                  const SizedBox(height: 10),
                  Text('Model Output:',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white70)),
                  if (diseases.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sick,
                                color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 6),
                            Text('Possible Diseases:',
                                style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: diseases
                              .map((disease) => Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orangeAccent.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.orangeAccent
                                            .withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      disease.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ...displayModel.entries.where((e) => e.key != 'diseases').map(
                      (e) => Text('${e.key}: ${e.value}',
                          style: TextStyle(color: Colors.white70))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Water Quality Report',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: null,
      ),
      drawer: AppDrawer(),
      body: Stack(
        children: [
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
          SafeArea(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.bar_chart,
                              size: 80,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _latestReport == null
                              ? Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          'No Reports Available',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Click below to generate your first report.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildReportView(_latestReport!),
                          const SizedBox(height: 30),
                          FloatingActionButton.extended(
                            onPressed: _loading ? null : _generateReport,
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            icon: Icon(Icons.add_chart),
                            label: Text('Generate Report',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            elevation: 8,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ApiService {
  static const String baseUrl =
      'https://your-vercel-app.vercel.app/api/predict'; // TODO: Replace with your Vercel deployment

  static Future<Map<String, dynamic>?> predictContamination(
      Map<String, dynamic> inputData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contamination'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(inputData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> predictDisease(
      Map<String, dynamic> inputData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/disease'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(inputData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
