import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Profile Fetcher',
      home: InstagramProfileFetcherScreen(),
    );
  }
}

class InstagramProfileFetcherScreen extends StatefulWidget {
  @override
  _InstagramProfileFetcherScreenState createState() => _InstagramProfileFetcherScreenState();
}

class _InstagramProfileFetcherScreenState extends State<InstagramProfileFetcherScreen> {
  final TextEditingController _usernameController = TextEditingController();
  List<String> _captions = [];
  bool _isLoading = false;
  final String _apifyApiToken = '<YOUR_APIFY_LINK>'; // Replace with your actual Apify API token

  Future<void> _fetchInstagramProfile() async {
    setState(() => _isLoading = true);
    _captions.clear();

    try {
      String username = _usernameController.text;
      String url = "https://www.instagram.com/$username/";

      Map<String, dynamic> runInput = {
        "directUrls": [url],
        "resultsType": "details",
        "resultsLimit": 200,
        "addParentData": false,
        "searchType": "hashtag",
        "searchLimit": 1,
      };

      var startResponse = await http.post(
        Uri.parse('https://api.apify.com/v2/acts/shu8hvrXbJbY3Eb9W/runs?token=$_apifyApiToken'),
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
          setState(() {
            _captions = data
                .expand((item) => item['latestPosts'])
                .map((post) => post['caption'] as String)
                .toList();
          });
        }
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
        title: Text('Instagram Profile Fetcher'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Enter Instagram Username'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchInstagramProfile,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Fetch Profile'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _captions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_captions[index]),
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
