import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Comment Scraper',
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
  List<dynamic> _comments = [];
  bool _isLoading = false;
  final String _apiToken = 'apify_api_goaFYQnxjfhU8ZYleBuifHudntaaKD0qhAV0'; // Your API token

  void _fetchComments() async {
    setState(() => _isLoading = true);
    String postUrl = _urlController.text;

    // Prepare the Actor input
    Map<String, dynamic> runInput = {
      "directUrls": [postUrl],
      "resultsLimit": 20,
    };

    try {
      // Start the Actor
      var startResponse = await http.post(
        Uri.parse('https://api.apify.com/v2/acts/apify~instagram-comment-scraper/runs?token=$_apiToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(runInput),
      );

      if (startResponse.statusCode == 201) {
        var runId = json.decode(startResponse.body)['data']['id'];

        // Fetch results from the dataset
        var datasetId = json.decode(startResponse.body)['data']['defaultDatasetId'];
        var datasetUrl = 'https://api.apify.com/v2/datasets/$datasetId/items?token=$_apiToken';
        await Future.delayed(Duration(seconds: 10)); // Wait for the actor to finish
        var datasetResponse = await http.get(Uri.parse(datasetUrl));

        if (datasetResponse.statusCode == 200) {
          setState(() {
            _comments = json.decode(datasetResponse.body);
          });
        } else {
          print('Failed to load comments. Status code: ${datasetResponse.statusCode}');
        }
      } else {
        print('Failed to start actor. Status code: ${startResponse.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instagram Comment Scraper'),
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
              onPressed: _fetchComments,
              child: _isLoading ? CircularProgressIndicator() : Text('Fetch Comments'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_comments[index].toString()),
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
