import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Comment Scraper with Moderation',
      home: InstagramCommentScraperScreen(),
    );
  }
}

class InstagramCommentScraperScreen extends StatefulWidget {
  @override
  _InstagramCommentScraperScreenState createState() => _InstagramCommentScraperScreenState();
}

class _InstagramCommentScraperScreenState extends State<InstagramCommentScraperScreen> {
  final TextEditingController _urlController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;
  final String _openaiApiToken = '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'; // Replace with your actual OpenAI API key
  final String _apifyApiToken = 'apify_api_goaFYQnxjfhU8ZYleBuifHudntaaKD0qhAV0'; // Replace with your actual Apify API token

  Future<void> _fetchAndModerateComments() async {
    setState(() => _isLoading = true);
    _comments.clear();
    await logToFile('Fetching and moderating comments...');

    try {
      String postUrl = _urlController.text;
      Map<String, dynamic> runInput = {
        "directUrls": [postUrl],
        "resultsLimit": 20,
      };

      var startResponse = await http.post(
        Uri.parse('https://api.apify.com/v2/acts/apify~instagram-comment-scraper/runs?token=$_apifyApiToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(runInput),
      );

      if (startResponse.statusCode == 201) {
        var datasetId = json.decode(startResponse.body)['data']['defaultDatasetId'];
        var isActorFinished = false;

        while (!isActorFinished) {
          await Future.delayed(Duration(seconds: 10));
          var statusResponse = await http.get(Uri.parse('https://api.apify.com/v2/actor-runs/${json.decode(startResponse.body)['data']['id']}?token=$_apifyApiToken'));

          if (statusResponse.statusCode == 200) {
            var statusData = json.decode(statusResponse.body);
            isActorFinished = statusData['data']['status'] == 'SUCCEEDED';
          }
        }

        var datasetUrl = 'https://api.apify.com/v2/datasets/$datasetId/items?token=$_apifyApiToken';
        var datasetResponse = await http.get(Uri.parse(datasetUrl));

        if (datasetResponse.statusCode == 200) {
          var data = json.decode(datasetResponse.body) as List;

          for (var item in data) {
            var moderationResponse = await http.post(
              Uri.parse('https://api.openai.com/v1/moderations'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_openaiApiToken',
              },
              body: json.encode({'input': item['text']}),
            );

            if (moderationResponse.statusCode == 200) {
              var responseBody = json.decode(moderationResponse.body);
              var results = responseBody['results'] as List;
              if (results.isNotEmpty) {
                var categories = results[0]['categories'] as Map;
                var flaggedCategories = categories.entries
                    .where((e) => e.value == true)
                    .map((e) => e.key)
                    .toList();

                if (flaggedCategories.isNotEmpty) {
                  _comments.add({
                    "text": item['text'],
                    "moderation": flaggedCategories.join(', '),
                  });
                  await logToFile('Flagged comment: ${item['text']}');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error: $e');
      await logToFile('Error: $e');
    } finally {
      setState(() => _isLoading = false);
      await logToFile('Fetching and moderation complete');
    }
  }

  Future<void> logToFile(String message) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/app_logs.txt');
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('$timestamp: $message\n', mode: FileMode.append);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instagram Comment Scraper with Moderation'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _urlController,
              decoration: InputDecoration(labelText: 'Enter Instagram Post URL'),
            ),
            ElevatedButton(
              onPressed: _fetchAndModerateComments,
              child: _isLoading ? CircularProgressIndicator() : Text('Fetch and Moderate Comments'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_comments[index]['text']),
                    subtitle: Text('Moderation Issues: ${_comments[index]['moderation']}'),
                    tileColor: Colors.redAccent.withOpacity(0.2),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
