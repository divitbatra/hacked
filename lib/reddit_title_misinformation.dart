import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:convert' show utf8, base64Encode;
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(RedditTitleMisinformation());

class RedditTitleMisinformation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reddit Post Analysis',
      home: RedditPostAnalysisPage(),
    );
  }
}

class RedditPostAnalysisPage extends StatefulWidget {
  @override
  _RedditPostAnalysisPageState createState() => _RedditPostAnalysisPageState();
}

class _RedditPostAnalysisPageState extends State<RedditPostAnalysisPage> {
  final _urlController = TextEditingController();
  String _response = '';
  String _postTitle = '';
  bool _isLoading = false;

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

  Future<void> _fetchRedditPostTitle() async {
    setState(() {
      _isLoading = true;
      _postTitle = '';
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
        setState(() {
          _postTitle = data[0]['data']['children'][0]['data']['title'];
        });
        await _analyzePostTitle(_postTitle);
      } else {
        print('Error fetching post title: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception caught: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzePostTitle(String title) async {
    final messages = [
      {"role": "system", "content": "You are an intelligent assistant."}
    ];

    if (title.isNotEmpty) {
      messages.add({"role": "user", "content": title});

      var requestBody = jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": messages,
      });

      var response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer <YOUR_OPENAI_API_KEY>' // Replace with your actual API key
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _response = 'Title: $title\nOpenAI Response: ${data['choices'][0]['message']['content']}';
        });
      } else {
        setState(() {
          _response = 'Error: ${response.statusCode}';
        });
      }
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
              TypewriterAnimatedText('Reddit Misinformation Detector',
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
          children: <Widget>[
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter Reddit Post URL',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchRedditPostTitle,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Fetch and Analyze Title'),
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
              child: ResponseBox(response: _response),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponseBox extends StatelessWidget {
  final String response;

  ResponseBox({required this.response});

  @override
  Widget build(BuildContext context) {
    List<String> parts = response.split('\n');
    String title = parts.length > 0 ? parts[0] : '';
    String apiResponse = parts.length > 1 ? parts.sublist(1).join('\n') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Box for the Title
        if (title.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: _boxDecoration(),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],

        // Box for the OpenAI Response
        if (apiResponse.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: _boxDecoration(),
            child: Text(
              apiResponse,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
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
    );
  }
}

