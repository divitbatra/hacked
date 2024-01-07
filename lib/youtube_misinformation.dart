import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(MisinformationDetector());

class MisinformationDetector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misinformation Detector',
      home: OpenAIChatPage(),
    );
  }
}

class OpenAIChatPage extends StatefulWidget {
  @override
  _OpenAIChatPageState createState() => _OpenAIChatPageState();
}

class _OpenAIChatPageState extends State<OpenAIChatPage> {
  final _textController = TextEditingController();
  String _response = '';

  void _sendMessage() async {
    final messages = [
      {"role": "system", "content": "You are an intelligent assistant."}
    ];

    String userMessage = _textController.text;
    if (userMessage.isNotEmpty) {
      messages.add({"role": "user", "content": "state true or false: $userMessage"});

      // Fetch the video title from YouTube API
      final videoTitle = await fetchVideoTitle(userMessage);

      // Add video title to the messages
      messages.add({"role": "assistant", "content": "Video Title: $videoTitle"});

      var requestBody = jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": messages,
      });

      var response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer <YOUR_OPENAI_API_KEY>', // Replace with your actual API key
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _response = data['choices'][0]['message']['content'];
        });
      } else {
        setState(() {
          _response = 'Error: ${response.statusCode}';
        });
      }
    }
  }

  Future<String> fetchVideoTitle(String videoUrl) async {
    final videoId = videoUrl.split("v=")[1];
    final apiKey = "<YOUR_GOOGLE_API_KEY>"; // Replace with your YouTube API key

    final url = Uri.parse(
        "https://www.googleapis.com/youtube/v3/videos?key=$apiKey&id=$videoId&part=snippet");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse["items"] != null && jsonResponse["items"].isNotEmpty) {
        return jsonResponse["items"][0]["snippet"]["title"];
      } else {
        return "Video not found";
      }
    } else {
      return "Error fetching video title";
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
                TypewriterAnimatedText(
                  'Misinformation Detector',
                  speed: const Duration(milliseconds: 100),
                ),
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
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter YouTube Video URL',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendMessage,
              child: Text('Fetch Video Title and Detect Misinformation'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseBox(response: _response),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ResponseBox extends StatelessWidget {
  final String response;

  ResponseBox({required this.response});

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
      child: Text(
        response,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
