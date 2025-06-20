import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theming/my_colors.dart';
import '../widgets/add_trallo.dart';

const String trelloApiKey = "e398b664116ed0be68c419dc0d0807df";
Future<void> checkTokenAndShowDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('trello_token');

  if (token == null || token.isEmpty) {
    // ما فيش توكن، نروح نجيب التوكن من صفحة TrelloTokenScreen
    final newToken = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => TrelloTokenScreen()),
    );

    if (newToken == null || newToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must provide Trello token to continue.')),
      );
      return;
    }

    await prefs.setString('trello_token', newToken);
  }

  showTrelloInputDialog(context);
}

class TrelloTokenScreen extends StatefulWidget {
  @override
  State<TrelloTokenScreen> createState() => _TrelloTokenScreenState();
}

class _TrelloTokenScreenState extends State<TrelloTokenScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('trello_token');
    if (savedToken != null) {
      _tokenController.text = savedToken;
    }
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid Trello token")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trello_token', token);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trello Token saved successfully')),
    );

    Navigator.pop(context, token); // ✅ رجّع التوكن
  }

  Future<void> _launchTokenUrl() async {
    final url =
        'https://trello.com/1/authorize?expiration=never&name=SpokifyApp&scope=read,write&response_type=token&key=$trelloApiKey';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Trello token URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: MyColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset("assets/images/arrow.png", width: 35, height: 35),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Enter Trello Token',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 80),
            GestureDetector(
              onTap: _launchTokenUrl,

        child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: MyColors.button1Color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    " 🔗 Get My Trello Token",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              decoration: BoxDecoration(
                color: MyColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: TextField(
                controller: _tokenController,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscureToken,
                maxLines: 1,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(16),
                  hintText: 'Paste Trello Token Here',
                  hintStyle: const TextStyle(color: MyColors.txt1Color),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureToken ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureToken = !_obscureToken;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _saveToken,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: MyColors.button1Color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    'Save Token',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
