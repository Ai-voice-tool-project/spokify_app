import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String trelloApiKey = "e398b664116ed0be68c419dc0d0807df";

class TrelloTokenWebViewScreen extends StatefulWidget {
  @override
  _TrelloTokenWebViewScreenState createState() => _TrelloTokenWebViewScreenState();
}

class _TrelloTokenWebViewScreenState extends State<TrelloTokenWebViewScreen> {
  late final WebViewController _controller;
  String? extractedToken;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) => _initWebView());
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            if (url.contains("token=")) {
              final uri = Uri.parse(url);
              final token = uri.fragment.split("token=").last;

              setState(() {
                extractedToken = token;
              });

              final prefs = await SharedPreferences.getInstance();
              if (userId != null) {
                // حفظ التوكن باسم userId
                await prefs.setString('trello_token_$userId', token);
              }

              Navigator.pop(context, token); // رجوع للتوكن
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
        'https://trello.com/1/authorize?expiration=never&name=SpokifyApp&scope=read,write&response_type=token&key=$trelloApiKey',
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Get Trello Token"),
        backgroundColor: Colors.black87,
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _controller),
    );
  }
}
