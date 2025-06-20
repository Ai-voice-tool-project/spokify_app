import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gradprj/core/helpers/ipconfig.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gradprj/core/helpers/spacing.dart';
import 'package:gradprj/core/routing/routes.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import '../widgets/CircleAvatar.dart';
import 'TrelloTokenScreen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool showEditFields = false;
  bool isDark = true;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController boardController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(text: "s1234567");

  String displayedName = "Loading...";
  String displayedEmail = "Loading...";
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        profileImageUrl = pickedFile.path;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', pickedFile.path);
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) return;

    final url = Uri.parse('http://$ipAddress:4000/api/v1/auth/user/$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'];

        setState(() {
          displayedName = user['userName'] ?? '';
          displayedEmail = user['email'] ?? '';
          profileImageUrl = user['profileImage'];
          nameController.text = displayedName;
          emailController.text = displayedEmail;
        });
      } else {
        print("❌ Failed to load user data");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: MyColors.backgroundColor,
        displayColor: MyColors.backgroundColor,
      ),
    );

    final ThemeData darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: MyColors.backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: MyColors.backgroundColor,
        foregroundColor: Colors.white,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );

    return Theme(
      data: isDark ? darkTheme : lightTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Image.asset("assets/images/arrow.png", width: 24, height: 24),
          ),
          title: const Text("Profile"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                verticalSpace(20),
                ImageCircleAvatar(
                  userName: displayedName,
                  imageUrl: profileImageUrl,
                  onImageTap: pickImage,
                ),
                const SizedBox(height: 10),
                Text(
                  displayedName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(displayedEmail),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit, color: MyColors.button1Color),
                  title: const Text('Edit Profile'),
                  trailing: Icon(showEditFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  onTap: () {
                    setState(() => showEditFields = !showEditFields);
                  },
                ),
                if (showEditFields) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('userName', nameController.text);
                      await prefs.setString('email', emailController.text);

                      setState(() {
                        displayedName = nameController.text;
                        displayedEmail = emailController.text;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated', style: TextStyle(color: Colors.white)),
                          backgroundColor: MyColors.backgroundColor,
                        ),
                      );
                    },
                    child: const Text("Save Changes"),
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.vpn_key, color: MyColors.button1Color),
                  title: const Text('Trello Token'),
                  subtitle: const Text('Manage your Trello authentication'),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onPressed: () async {
                      final updatedToken = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TrelloTokenScreen()),
                      );

                      if (updatedToken != null && updatedToken is String) {
                        print("✅ Trello Token Updated: $updatedToken");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تحديث Trello Token')),
                        );
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings, color: MyColors.button1Color),
                  title: const Text('Mode'),
                  subtitle: const Text('Dark & Light'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) => setState(() => isDark = value),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help, color: MyColors.button1Color),
                  title: const Text('About'),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () => Navigator.pushNamed(context, Routes.about),
                  ),
                ),
                const SizedBox(height: 25),
                // زر تسجيل الخروج
                TextButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId');

                    if (userId != null) {
                      try {
                        final url = Uri.parse('http://$ipAddress:4000/logout/');
                        final response = await http.post(
                          url,
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'user_id': userId}),
                        );

                        if (response.statusCode == 200) {
                          print("✅ User vectorstore deleted from server.");
                        } else {
                          print("⚠️ Failed to delete vectorstore: ${response.body}");
                        }
                      } catch (e) {
                        print("⚠️ Error deleting vectorstore: $e");
                      }
                    }

                    await prefs.clear();

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.login,
                          (route) => false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out')),
                    );
                  },
                  icon: Transform.rotate(
                    angle: 3.1416,
                    child: const Icon(
                      Icons.logout,
                      color: MyColors.button1Color,
                      size: 25,
                    ),
                  ),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: MyColors.button1Color, fontSize: 20),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
