import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

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
  final String _openaiApiToken = '<YOUR_OPENAI_API_KEY>'; // Replace with your actual OpenAI API key
  final String _apifyApiToken = '<YOUR_APIFY_API_KEY>'; // Replace with your actual Apify API token

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
        title: SizedBox(
          width: 250.0,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText('Instagram Comments Moderator',
                  speed: const Duration(milliseconds: 100),),
              ],
              totalRepeatCount: 1,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Enter Instagram Post URL',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchAndModerateComments,
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Fetch and Moderate Comments'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  onPrimary: Colors.white, // Text color
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Smaller padding
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Smaller font size
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Rounded corners
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    return CommentBox(comment: _comments[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentBox extends StatelessWidget {
  final Map<String, dynamic> comment;

  CommentBox({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            comment['text'],
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Moderation Issues: ${comment['moderation']}',
            style: TextStyle(fontSize: 14, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
