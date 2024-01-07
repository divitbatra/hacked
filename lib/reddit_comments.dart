import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:convert' show utf8, base64Encode;
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(RedditCommentsModerationApp());

class RedditCommentsModerationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reddit Comment Moderation',
      home: CaptionModerationScreen(),
    );
  }
}

class CaptionModerationScreen extends StatefulWidget {
  @override
  _CaptionModerationScreenState createState() => _CaptionModerationScreenState();
}

class _CaptionModerationScreenState extends State<CaptionModerationScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, String> _moderationResults = {};
  String _noIssueMessage = '';
  final String _openAiApiKey = '<YOUR_OPENAI_API_KEY>'; // Replace with your actual OpenAI API key

  Future<String> _getRedditAccessToken() async {
    String clientId = '<YOUR_REDDIT_CLIENT_ID>';
    String clientSecret = '<YOUR_REDDIT_CLIENT_SECRET>';
    String username = '<YOUR_REDDIT_USERNAME>';
    String password = '<YOUR_REDDIT_PASSWORD>';

    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret'));
    var response = await http.post(
      Uri.parse('https://www.reddit.com/api/v1/access_token'),
      headers: <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=password&username=$username&password=$password',
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to obtain access token');
    }
  }

  void _fetchRedditComments() async {
    setState(() {
      _isLoading = true;
      _moderationResults.clear();
      _noIssueMessage = '';
    });

    try {
      String accessToken = await _getRedditAccessToken();

      String url = _urlController.text;
      Uri parsedUrl = Uri.parse(url);
      List<String> pathSegments = parsedUrl.pathSegments;
      int commentsIndex = pathSegments.indexOf('comments');
      if (commentsIndex == -1 || commentsIndex >= pathSegments.length - 1) {
        print('Invalid URL format');
        return;
      }
      String submissionId = pathSegments[commentsIndex + 1];

      String apiUrl = 'https://oauth.reddit.com/comments/$submissionId';

      var response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'bearer $accessToken',
          'User-Agent': 'YourUserAgent',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> commentsData = data[1]['data']['children'];

        for (var commentData in commentsData) {
          String commentBody = commentData['data']['body'];
          await _moderateText(commentBody);
        }

        if (_moderationResults.isEmpty) {
          setState(() {
            _noIssueMessage = 'No moderation issues found for any comments.';
          });
        }
      }
    } catch (e) {
      print('Exception caught: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _moderateText(String text) async {
    try {
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
              TypewriterAnimatedText('Reddit Comments Moderator',
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
              controller: _urlController,
              decoration: InputDecoration(labelText: 'Enter Reddit Post URL'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchRedditComments,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Fetch and Moderate Comments'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
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
                  String comment = _moderationResults.keys.elementAt(index);
                  return CommentBox(comment: comment, issues: _moderationResults[comment]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentBox extends StatelessWidget {
  final String comment;
  final String? issues;

  CommentBox({required this.comment, this.issues});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 8),
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
        children: [
          Text(
            comment,
            style: TextStyle(fontSize: 16),
          ),
          if (issues != null && issues!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Moderation Issues: $issues',
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}
