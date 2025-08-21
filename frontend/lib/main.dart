import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Entry point for the Flutter application.
///
/// This widget builds a very simple UI that allows users to create
/// gigs and view a list of existing gigs.  The app communicates with
/// the Spring Boot backend via HTTP calls on localhost.
void main() {
  runApp(const GigMeApp());
}

class GigMeApp extends StatelessWidget {
  const GigMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GigMe',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  List<dynamic> _gigs = [];

  /// Base URL of the backend.  Change this if your API is served from
  /// another host or port.
  static const String baseUrl = 'http://localhost:8080/api/gigs';

  @override
  void initState() {
    super.initState();
    _fetchGigs();
  }

  /// Fetch the list of gigs from the backend.
  Future<void> _fetchGigs() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        setState(() {
          _gigs = json.decode(response.body);
        });
      }
    } catch (e) {
      // In a real app you might show an error message to the user
      debugPrint('Error fetching gigs: $e');
    }
  }

  /// Create a new gig by posting to the backend.  On success the
  /// form is cleared and the list refreshed.
  Future<void> _createGig() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    if (title.isEmpty || description.isEmpty) {
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'description': description,
          'budget': budget,
        }),
      );
      if (response.statusCode == 200) {
        _titleController.clear();
        _descriptionController.clear();
        _budgetController.clear();
        _fetchGigs();
      }
    } catch (e) {
      debugPrint('Error creating gig: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GigMe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Gig',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(labelText: 'Budget'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _createGig,
              child: const Text('Create'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gigs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _gigs.length,
              itemBuilder: (context, index) {
                final gig = _gigs[index] as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(gig['title'] ?? ''),
                    subtitle: Text(gig['description'] ?? ''),
                    trailing: Text('₹${(gig['budget'] ?? 0).toString()}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}