import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preference_viewer/shared_preference_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Preference Viewer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<void> _addMockData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', 'John Doe');
    await prefs.setInt('userAge', 30);
    await prefs.setDouble('userHeight', 5.9);
    await prefs.setBool('isSubscribed', true);
    await prefs.setStringList('favoriteColors', ['Red', 'Green', 'Blue']);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock data added!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SharedPrefs Viewer Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _addMockData,
              child: const Text('Add Mock Data'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                SharedPrefsViewer.navigate(context);
              },
              child: const Text('Open Viewer'),
            ),
          ],
        ),
      ),
    );
  }
}
