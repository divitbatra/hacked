import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(CaptionModerationApp());

class CaptionModerationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Caption Moderation',
      home: CaptionModerationScreen(),
    );
  }
}

class CaptionModerationScreen extends StatefulWidget {
  @override
  _CaptionModerationScreenState createState() => _CaptionModerationScreenState();
}

class _CaptionModerationScreenState extends State<CaptionModerationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  List<String> _captions = [];
  bool _isLoading = false;
  Map<String, String> _moderationResults = {};
  String _noIssueMessage = '';
  final String _apifyApiToken = '<YOUR_APIFY_API_KEY>'; // Replace with your actual Apify API token
  final String _openAiApiKey = '<YOUR_OPENAI_API_KEY>'; // Replace with your actual OpenAI API key

  Future<void> _fetchInstagramProfile() async {
    setState(() {
      _isLoading = true;
      _noIssueMessage = '';
    });
    _captions.clear();
    _moderationResults.clear();

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
          _captions = data
              .expand((item) => item['latestPosts'])
              .map((post) => post['caption'] as String)
              .toList();

          for (var caption in _captions) {
            await _moderateText(caption);
          }

          if (_moderationResults.isEmpty) {
            setState(() {
              _noIssueMessage = 'No moderation issues found for any captions.';
            });
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moderateText(String text) async {
    try {
      // Remove hashtags from the text
      text = text.replaceAll(RegExp(r'#\w+'), '');

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/moderations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: json.encode({'input': text}),
      );

      var responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        var results = responseBody['results'] as List;
        if (results.isNotEmpty) {
          var categories = results[0]['categories'] as Map;
          var flaggedCategories = categories.entries
              .where((e) => e.value == true)
              .map((e) => e.key)
              .toList();

          if (flaggedCategories.isNotEmpty) {
            setState(() {
              _moderationResults[text] = flaggedCategories.join(', ');
            });
          }
        }
      }
    } catch (e) {
      print('Error in moderation: $e');
    }
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
              TypewriterAnimatedText('Instagram Captions Moderator',
                speed: const Duration(milliseconds: 100),),
            ],
            totalRepeatCount: 1,
          ),
        ),
      ),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchInstagramProfile,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Fetch and Moderate Captions'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white, // Text color
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _moderationResults.isEmpty && _noIssueMessage.isNotEmpty
                  ? Center(child: Text(_noIssueMessage))
                  : ListView.builder(
                itemCount: _moderationResults.length,
                itemBuilder: (context, index) {
                  String caption = _moderationResults.keys.elementAt(index);
                  return CaptionBox(caption: caption, issues: _moderationResults[caption]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaptionBox extends StatelessWidget {
  final String caption;
  final String? issues;

  CaptionBox({required this.caption, this.issues});

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
            caption,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          if (issues != null && issues!.isNotEmpty)
            Text(
              'Moderation Issues: $issues',
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }
}
