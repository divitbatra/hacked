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
  List<String> _comments = [];
  bool _isLoading = false;
  final String _apiToken = 'apify_api_goaFYQnxjfhU8ZYleBuifHudntaaKD0qhAV0'; // Your API token

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    print('Fetching comments...');

    try {
      String postUrl = _urlController.text;
      Map<String, dynamic> runInput = {
        "directUrls": [postUrl],
        "resultsLimit": 20,
      };

      var startResponse = await http.post(
        Uri.parse('https://api.apify.com/v2/acts/apify~instagram-comment-scraper/runs?token=$_apiToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(runInput),
      );

      print('Start response status: ${startResponse.statusCode}');
      print('Start response body: ${startResponse.body}');

      if (startResponse.statusCode == 201) {
        var datasetId = json.decode(startResponse.body)['data']['defaultDatasetId'];
        var isActorFinished = false;

        while (!isActorFinished) {
          await Future.delayed(Duration(seconds: 10));
          var statusResponse = await http.get(Uri.parse('https://api.apify.com/v2/actor-runs/${json.decode(startResponse.body)['data']['id']}?token=$_apiToken'));

          print('Status response status: ${statusResponse.statusCode}');
          print('Status response body: ${statusResponse.body}');

          if (statusResponse.statusCode == 200) {
            var statusData = json.decode(statusResponse.body);
            isActorFinished = statusData['data']['status'] == 'SUCCEEDED';
          }
        }

        var datasetUrl = 'https://api.apify.com/v2/datasets/$datasetId/items?token=$_apiToken';
        var datasetResponse = await http.get(Uri.parse(datasetUrl));

        print('Dataset response status: ${datasetResponse.statusCode}');
        print('Dataset response body: ${datasetResponse.body}');

        if (datasetResponse.statusCode == 200) {
          var data = json.decode(datasetResponse.body) as List;
          setState(() {
            _comments = data.map((item) => '"${item['ownerUsername']}": "${item['text']}"').toList();
            print('Comments fetched: ${_comments.length}');
          });
        }
      }
    } catch (e) {
      print('Error in _fetchComments: $e');
    } finally {
      setState(() {
        _isLoading = false;
        print('Loading complete');
      });
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
                    title: Text(_comments[index]),
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
