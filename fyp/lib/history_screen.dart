import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_drawer.dart';
import 'dart:ui';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReports();
  }

  Future<void> _loadUserReports() async {
    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      // Listen to real-time updates for user reports
      _dbRef.child('user_reports').child(user.uid).onValue.listen((event) {
        if (event.snapshot.value != null) {
          final reports = <Map<String, dynamic>>[];
          final data = event.snapshot.value as Map<dynamic, dynamic>;

          data.forEach((key, value) {
            final report = Map<String, dynamic>.from(value as Map);
            report['key'] = key;
            reports.add(report);
          });

          // Sort reports by timestamp in descending order (newest first)
          reports.sort((a, b) {
            final aTime = DateTime.parse(a['timestamp'] as String);
            final bTime = DateTime.parse(b['timestamp'] as String);
            return bTime.compareTo(aTime);
          });

          setState(() {
            _reports = reports;
            _loading = false;
          });
        } else {
          setState(() {
            _reports = [];
            _loading = false;
          });
        }
      }, onError: (error) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $error')),
        );
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reports: $e')),
      );
    }
  }

  Future<void> _deleteReport(String reportKey) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _dbRef
          .child('user_reports')
          .child(user.uid)
          .child(reportKey)
          .remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Report History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Reports Found',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate reports to see them here',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          final sensors =
                              report['sensors'] as Map<dynamic, dynamic>?;
                          final model =
                              report['model_output'] as Map<dynamic, dynamic>?;
                          final turbidity = double.tryParse(
                                  sensors?['turbidity']?.toString() ?? '') ??
                              0;
                          final bool isTurbiditySafe =
                              turbidity >= 1800 && turbidity <= 2500;
                          final bool contaminated = isTurbiditySafe
                              ? false
                              : model?['contaminated'] == true;
                          final List<dynamic> diseases = isTurbiditySafe
                              ? []
                              : model?['diseases'] is List
                                  ? model!['diseases']
                                  : [];

                          return Dismissible(
                            key: Key(report['key']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (direction) {
                              _deleteReport(report['key']);
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.blue.shade900.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ListTile(
                                          leading: CircleAvatar(
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
                                          title: Text(
                                            report['readable_time'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          subtitle: Text(
                                            contaminated
                                                ? 'Contaminated'
                                                : 'Not Contaminated',
                                            style: TextStyle(
                                              color: contaminated
                                                  ? Colors.redAccent
                                                  : Colors.greenAccent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  backgroundColor:
                                                      Colors.blue.shade900,
                                                  title: const Text(
                                                    'Delete Report',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to delete this report?',
                                                    style: TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: const Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _deleteReport(
                                                            report['key']);
                                                      },
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .redAccent),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (diseases.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Detected Diseases:',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children:
                                                      diseases.map((disease) {
                                                    final diseaseName = disease
                                                            is Map
                                                        ? disease['name']
                                                            ?.toString()
                                                        : disease.toString();

                                                    return Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .orangeAccent
                                                            .withOpacity(0.4),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                          color: Colors
                                                              .orangeAccent
                                                              .withOpacity(0.8),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        diseaseName ??
                                                            'Unknown Disease',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 0, 16, 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Sensor Readings:',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...?sensors?.entries.map((e) =>
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4),
                                                    child: Text(
                                                      '${e.key}: ${e.value}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
