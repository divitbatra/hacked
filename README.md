# Flutter Social Media Moderation and Analysis App
This Flutter project is a comprehensive social media moderation and analysis application designed for various platforms including Instagram, Reddit, and YouTube. The app offers a range of features such as comment scraping, caption moderation, misinformation detection, and analysis of social media posts. Each social media platform is catered to with specific Dart files and functionalities.

# Key Features:

Social Media Integration: Modules for Instagram (instagram.dart), Reddit (reddit.dart), and YouTube (youtube.dart) allow for direct interaction with these platforms.
Comment Scraper and Moderation: Dedicated modules for Instagram (instagram_comment_scraper_screen.dart), Reddit (reddit_comments.dart), and YouTube (youtube_comments_moderation.dart) enable scraping and moderating comments.
Misinformation Detection: Files like misinformation.dart, reddit_title_misinformation.dart, and youtube_misinformation.dart focus on detecting and analyzing misinformation in social media content.
User Interface Components: Various StatelessWidget and StatefulWidget classes provide a responsive and interactive UI for each feature of the app.
OpenAI Integration: Some modules utilize OpenAI for chat and analysis functionalities, enhancing the app's capability to detect misinformation and moderate content.

# Technical Details:

The application is structured in a modular fashion, with each major functionality encapsulated in its Dart file.
The use of Flutter's StatelessWidget and StatefulWidget provides a dynamic and responsive user interface.
Integration with external APIs for social media platforms and OpenAI is a key aspect of the application, enabling real-time data fetching and processing.

# Potential Applications:

This app can be used by social media managers, content moderators, and researchers to analyze and moderate content on major social media platforms.
It can also serve as an educational tool for understanding the impact of misinformation and the mechanics of content moderation in the digital age.

# Component Breakdown

1) button_page.dart

Components:
ButtonPage: A StatelessWidget for button-related UI.

2) caption_moderation.dart

Components:
CaptionModerationApp: A StatelessWidget that likely initializes the caption moderation feature.
CaptionModerationScreen: A StatefulWidget responsible for the main UI of caption moderation.
CaptionBox: A StatelessWidget for displaying captions.
Functions:
main: Entry point of the app/module.
_fetchInstagramProfile: Function to fetch Instagram profiles.
_moderateText: Function for moderating text.

3) instagram.dart

Components:
InstagramPage: A StatelessWidget likely representing the Instagram-related page or functionality.

4) instagram_comment_scraper_screen.dart

Components:
MyApp: A StatelessWidget, probably the main entry for this module.
InstagramCommentScraperScreen: A StatefulWidget for scraping Instagram comments.
CommentBox: A StatelessWidget for displaying comments.
Functions:
main: Entry point of the app/module.
_fetchAndModerateComments: Fetches and moderates Instagram comments.
logToFile: Function to log data to a file.

5) main.dart

Components:
MyApp: Main entry StatelessWidget for the app.
Functions:
main: Entry point of the app.

6) misinformation.dart

Components:
MisinformationDetector: A StatelessWidget likely for detecting misinformation.
OpenAIChatPage: A StatefulWidget for an OpenAI-powered chat interface.
ResponseBox: A StatelessWidget for displaying responses.
Functions:
main: Entry point of the app/module.
_sendMessage: Function to send messages, possibly to the OpenAI chat interface.

7) reddit.dart

Components:
RedditPage: A StatelessWidget representing the Reddit-related page or functionality.

8) reddit_comments.dart

Components:
RedditCommentsModerationApp: A StatelessWidget, likely the main entry for Reddit comments moderation.
CaptionModerationScreen: A StatefulWidget for the main UI of caption moderation.
CommentBox: A StatelessWidget for displaying comments.
Functions:
main: Entry point of the app/module.
_getRedditAccessToken: Fetches access token for Reddit API.
_fetchRedditComments: Fetches comments from Reddit.
_moderateText: Moderates the text of comments.

9) reddit_title_misinformation.dart

Components:
RedditTitleMisinformation: A StatelessWidget for analyzing misinformation in Reddit titles.
RedditPostAnalysisPage: A StatefulWidget for Reddit post title analysis.
ResponseBox: A StatelessWidget for displaying analysis responses.
Functions:
main: Entry point of the app/module.
_getRedditAccessToken: Function to get access token for Reddit.
_fetchRedditPostTitle: Fetches Reddit post titles.
_analyzePostTitle: Analyzes the Reddit post title for misinformation.

10) youtube.dart

Components:
YoutubePage: A StatelessWidget for YouTube-related functionality.

11) youtube_comments_moderation.dart

Components:
YoutubeModerationScreen: A StatelessWidget for YouTube comment moderation.
MyHomePage: A StatefulWidget for the home page layout.
CommentBox: A StatelessWidget for displaying comments.
Functions:
main: Entry point of the app/module.
fetchAndModerateComments: Fetches and moderates YouTube comments.
fetchComments: Function to fetch comments from YouTube.
moderateComments: Function to moderate comments.

12) youtube_misinformation.dart

Components:
MisinformationDetector: A StatelessWidget for detecting misinformation.
OpenAIChatPage: A StatefulWidget for an OpenAI-powered chat interface.
ResponseBox: A StatelessWidget for displaying responses.
Functions:
main: Entry point of the app/module.
_sendMessage: Function to send messages, possibly to the OpenAI chat interface.
fetchVideoTitle: Fetches YouTube video titles.
dispose: A method for disposing resources.

