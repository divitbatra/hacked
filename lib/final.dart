import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(ModerationApp());

class ModerationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Moderation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ModerationHomePage(),
    );
  }
}

class ModerationHomePage extends StatefulWidget {
  @override
  _ModerationHomePageState createState() => _ModerationHomePageState();
}

class _ModerationHomePageState extends State<ModerationHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  void _moderateText() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/moderations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer <YOUR_OPENAI_API_KEY', // Replace with your actual API key
        },
        body: json.encode({'input': _controller.text}),
      );

      var responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          var results = responseBody['results'] as List;
          if (results.isNotEmpty) {
            var categories = results[0]['categories'] as Map;
            var flaggedCategories = categories.entries
                .where((e) => e.value == true)
                .map((e) => e.key)
                .toList();

            if (flaggedCategories.isNotEmpty) {
              _result = flaggedCategories.join(', ');
            } else {
              _result = 'No moderation issues found.';
            }
          } else {
            _result = 'No moderation results found';
          }
        });
      } else {
        setState(() {
          _result = 'Error: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Moderation'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter text to moderate',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _moderateText,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Moderate'),
            ),
            SizedBox(height: 20),
            Text(
              'Moderation Issues: $_result',
              style: TextStyle(
                color: _result.contains('No moderation issues found') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
