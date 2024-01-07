import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animated_text_kit/animated_text_kit.dart';

void main() {
  runApp(YoutubeModerationScreen());
}

class YoutubeModerationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Comment Moderation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final apikey = '<YOUR_GOOGLE_API_KEY>'; // Replace with your YouTube Data API key
  final moderationApiKey = '<YOUR_OPENAI_API_KEY>'; // Replace with your Moderation API key
  final videoUrlController = TextEditingController();
  List<String> comments = [];
  List<String> moderatedComments = [];
  bool isLoading = false;

  String getVideoId(String videoUrl) {
    if (videoUrl.contains('youtu.be')) {
      return videoUrl.split('/').last;
    } else if (videoUrl.contains('youtube.com')) {
      final videoId = videoUrl.split('v=')[1];
      final ampersandIndex = videoId.indexOf('&');
      return ampersandIndex != -1 ? videoId.substring(0, ampersandIndex) : videoId;
    }
    return '';
  }

  Future<void> fetchAndModerateComments() async {
    setState(() {
      isLoading = true;
      moderatedComments.clear();
    });

    await fetchComments();
    await moderateComments();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchComments() async {
    final videoId = getVideoId(videoUrlController.text);
    final url = Uri.parse('https://www.googleapis.com/youtube/v3/commentThreads'
        '?part=snippet'
        '&videoId=$videoId'
        '&maxResults=20'
        '&key=$apikey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List<dynamic>;
      comments.clear();
      for (final item in items) {
        final topComment = item['snippet']['topLevelComment']['snippet'];
        comments.add(topComment['textDisplay']);
      }
    } else {
      print('Error fetching comments: ${response.statusCode}, ${response.body}');
    }
  }

  Future<void> moderateComments() async {
    for (var comment in comments) {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/moderations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $moderationApiKey',
        },
        body: json.encode({'input': comment}),
      );

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        var results = responseBody['results'] as List;
        if (results.isNotEmpty) {
          var categories = results[0]['categories'] as Map;
          var flagged = categories.entries.where((e) => e.value == true);
          if (flagged.isNotEmpty) {
            var issues = flagged.map((e) => e.key).join(', ');
            moderatedComments.add('$comment\nModeration Issues: $issues');
          }
        }
      } else {
        print('Error in moderation: ${response.statusCode}, ${response.body}');
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
              TypewriterAnimatedText('YT Comments Moderator',
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
              controller: videoUrlController,
              decoration: InputDecoration(
                labelText: 'Enter the video URL',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: isLoading ? null : fetchAndModerateComments,
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('Fetch and Moderate Comments'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: moderatedComments.isEmpty
                  ? Center(child: Text('No moderation issues found.'))
                  : ListView.builder(
                itemCount: moderatedComments.length,
                itemBuilder: (context, index) {
                  return CommentBox(comment: moderatedComments[index]);
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

  CommentBox({required this.comment});

  @override
  Widget build(BuildContext context) {
    List<String> parts = comment.split('\nModeration Issues: ');
    String commentText = parts.length > 0 ? parts[0] : '';
    String issues = parts.length > 1 ? 'Moderation Issues: ${parts[1]}' : '';

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
            commentText,
            style: TextStyle(fontSize: 16),
          ),
          if (issues.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              issues,
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}
