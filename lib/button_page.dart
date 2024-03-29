import 'package:flutter/material.dart';
// Import all your page classes
import 'misinformation.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'reddit.dart';
import 'instagram.dart';
import 'youtube.dart';
import 'package:social_media_buttons/social_media_icons.dart';

class ButtonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/image.jpg"),
              // Replace with your image path
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4), // 40% opacity
                BlendMode.dstATop,
              ),
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 350.0,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Choose from the following platforms',
                            speed: const Duration(milliseconds: 100),
                          ),
                        ],
                        totalRepeatCount: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildElevatedButton(
                    context,
                    'Instagram',
                    InstagramPage(),
                      Icon(SocialMediaIcons.instagram)
                  ),

                  SizedBox(height: 10),
                  _buildElevatedButton(
                    context,
                    'Reddit',
                    RedditPage(),
                    Icon(SocialMediaIcons.reddit),
                  ),
                  SizedBox(height: 10),
                  _buildElevatedButton(
                      context,
                      'YouTube',
                      YoutubePage(),
                      Icon(SocialMediaIcons.youtube)

                  ),
                  SizedBox(height: 10),
                  _buildElevatedButton(
                    context,
                    'Misinformation Detector',
                    MisinformationDetector(),
                    Icon(SocialMediaIcons.android),
                  ),

                  // ... [Add other ElevatedButton widgets here with SizedBox for spacing]
                ],
              ),
            ),
          ),
        )
    );
  }
}

  Widget _buildElevatedButton(BuildContext context, String text, Widget destination, Icon SocialMediaIcon) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          },
          child: SocialMediaIcon
        ),
        style: ElevatedButton.styleFrom(
          primary: Colors.blue,
          onPrimary: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

