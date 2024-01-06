import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(HateSpeechDetectorApp());
}

class HateSpeechDetectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hate Speech Detector',
      home: HateSpeechDetectorScreen(),
    );
  }
}

class HateSpeechDetectorScreen extends StatefulWidget {
  @override
  _HateSpeechDetectorScreenState createState() =>
      _HateSpeechDetectorScreenState();
}

class _HateSpeechDetectorScreenState extends State<HateSpeechDetectorScreen> {
  TextEditingController textController = TextEditingController();
  String result = '';

  Future<void> checkHateSpeech(String text) async {
    final apiUrl = Uri.parse('https://twinword-sentiment-analysis.p.rapidapi.com/analyze/');

    final response = await http.post(
      apiUrl,
      headers: {
        'content-type': 'application/x-www-form-urlencoded',
        'X-RapidAPI-Key': 'beae8c3a10msh6b06844bcdf317ap1d9c9djsn2592ac3ff386',
        'X-RapidAPI-Host': 'twinword-sentiment-analysis.p.rapidapi.com',
      },
      body: {
        'text': text,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final sentimentType = data['type'];

      if (sentimentType == 'negative') {
        result = 'Hate Speech Detected';
      } else {
        result = 'Not Hate Speech';
      }
    } else {
      result = 'Error occurred while checking hate speech';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hate Speech Detector'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(labelText: 'Enter Text'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                final inputText = textController.text;
                if (inputText.isNotEmpty) {
                  checkHateSpeech(inputText);
                }
              },
              child: Text('Check Hate Speech'),
            ),
            SizedBox(height: 20.0),
            Text(
              result,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
