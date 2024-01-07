import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAI Chat',
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
      {"role": "system", "content": "You are a intelligent assistant."}
    ];

    String userMessage = _textController.text;
    if (userMessage.isNotEmpty) {
      messages.add({"role": "user", "content": "state true or false: $userMessage"});

      var requestBody = jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": messages,
      });

      print('Request body: $requestBody'); // Debugging

      var response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer <YOUR_OPENAI_API_KEY>' // Replace with your actual API key
        },
        body: requestBody,
      );

      print('Response status: ${response.statusCode}'); // Debugging
      print('Response body: ${response.body}'); // Debugging

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
                TypewriterAnimatedText('Misinformation Detector',
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
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter your message',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendMessage,
              child: Text('Send'),
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
              child: SingleChildScrollView(
                child: ResponseBox(response: _response),
              ),
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
