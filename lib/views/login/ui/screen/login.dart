// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'package:gradprj/core/helpers/app_bar.dart';
// import 'package:gradprj/core/helpers/custom_raised_gradientbutton.dart';
// import 'package:gradprj/core/helpers/spacing.dart';
// import 'package:gradprj/core/routing/routes.dart';
// import 'package:gradprj/core/theming/my_colors.dart';
// import 'package:gradprj/core/theming/my_fonts.dart';
// import 'package:gradprj/core/widgets/text_form_field.dart';
// import 'package:gradprj/views/login/ui/widgets/do_not_have_an_account.dart';
//
// import '../../../../core/helpers/ipconfig.dart';
//
// class Login extends StatefulWidget {
//   const Login({super.key});
//
//   @override
//   State<Login> createState() => _LoginState();
// }
//
// class _LoginState extends State<Login> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//
//   bool isLoading = false;
//   bool passwordVisible = false;
//
//   Future<void> loginUser() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       isLoading = true;
//     });
//
//     final url = Uri.parse('http://$ipAddress:4000/api/v1/auth/login');
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "email": emailController.text.trim(),
//           "password": passwordController.text.trim(),
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//
//         final user = responseData['user'];
//         final userId = user?['id'];
//         final userName = user?['userName'] ?? '';
//         final email = user?['email'] ?? '';
//         final password = passwordController.text.trim();
//
//         if (userId != null && userId is String) {
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setString('userId', userId);
//           if (userName.isNotEmpty) await prefs.setString('userName', userName);
//           if (email.isNotEmpty) await prefs.setString('userEmail', email);
//           if (password.isNotEmpty) await prefs.setString('userPassword', password);
//
//           print('✅ Saved userId: $userId');
//           print('✅ Saved userName: $userName');
//           print('✅ Saved email: $email');
//           print('✅ Saved password: $password');
//
//           Navigator.pushReplacementNamed(context, Routes.home);
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("❌ userId not found in response")),
//           );
//         }
//       } else {
//         final errorData = jsonDecode(response.body);
//         String errorMsg = errorData['message'] ?? 'Login failed';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMsg)),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MyColors.backgroundColor,
//       resizeToAvoidBottomInset: true,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const AppBarOfSpokify(),
//                   verticalSpace(100),
//                   Text(
//                     "Welcome",
//                     style: MyFontStyle.font45Regular
//                         .copyWith(color: MyColors.whiteColor, height: 1.0),
//                   ),
//                   Text(
//                     "Back!",
//                     style: MyFontStyle.font45Bold
//                         .copyWith(color: MyColors.txt1Color, height: 1.0),
//                   ),
//                   verticalSpace(20),
//                   MyTextFormField(
//                     controller: emailController,
//                     hint: "Email Address",
//                     isObecure: false,
//                     prefixIcon: Icon(Icons.email_outlined, color: MyColors.fontColor),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter email';
//                       }
//                       if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   verticalSpace(20),
//                   MyTextFormField(
//                     controller: passwordController,
//                     hint: "Password",
//                     isObecure: !passwordVisible,
//                     prefixIcon: Icon(Icons.lock, color: MyColors.fontColor),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         passwordVisible ? Icons.visibility : Icons.visibility_off,
//                         color: MyColors.fontColor,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           passwordVisible = !passwordVisible;
//                         });
//                       },
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter password';
//                       }
//                       if (value.length < 6) {
//                         return 'Password must be at least 6 characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   verticalSpace(30),
//                   isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : CustomRaisedGradientButton(
//                     onPressed: loginUser,
//                     width: 350,
//                     text: 'LOG IN',
//                   ),
//                   verticalSpace(20),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushNamed(context, Routes.forget_password);
//                     },
//                     child: Text(
//                       "Forgot Password?",
//                       style: MyFontStyle.font11RegularUnderline.copyWith(
//                         color: MyColors.whiteColor,
//                         decoration: TextDecoration.underline,
//                         decorationColor: MyColors.whiteColor,
//                       ),
//                     ),
//                   ),
//                   verticalSpace(10),
//                   const DonotHaveAnAccountRow(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gradprj/core/helpers/app_bar.dart';
import 'package:gradprj/core/helpers/custom_raised_gradientbutton.dart';
import 'package:gradprj/core/helpers/spacing.dart';
import 'package:gradprj/core/routing/routes.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import 'package:gradprj/core/theming/my_fonts.dart';
import 'package:gradprj/core/widgets/text_form_field.dart';
import 'package:gradprj/views/login/ui/widgets/do_not_have_an_account.dart';

import '../../../../core/helpers/ipconfig.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool passwordVisible = false;

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://$ipAddress:4000/api/v1/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final user = responseData['user'];
        final userId = user?['id'];
        final userName = user?['userName'] ?? '';
        final email = user?['email'] ?? '';
        final password = passwordController.text.trim();

        if (userId != null && userId is String) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId);
          if (userName.isNotEmpty) await prefs.setString('userName', userName);
          if (email.isNotEmpty) await prefs.setString('userEmail', email);
          if (password.isNotEmpty) await prefs.setString('userPassword', password);

          print('✅ Saved userId: $userId');
          print('✅ Saved userName: $userName');
          print('✅ Saved email: $email');
          print('✅ Saved password: $password');

          // بعد تسجيل الدخول، جيب الترنسكريبشن وبعتهم لـ Chroma
          await syncUserTranscriptionsToChroma(userId);

          Navigator.pushReplacementNamed(context, Routes.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ userId not found in response")),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        String errorMsg = errorData['message'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> syncUserTranscriptionsToChroma(String userId) async {
    final url = Uri.parse('http://192.168.1.102:4000/api/transcriptions/user/$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List transcriptions = data['transcriptions'] ?? [];

        for (var item in transcriptions) {
          final transcriptionText = item['transcription'] as String? ?? '';

          if (transcriptionText.isNotEmpty) {
            await addTextToChroma(userId, transcriptionText);
          }
        }
        print("✅ All transcriptions synced to Chroma.");
      } else {
        print("Failed to load transcriptions with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error syncing transcriptions: $e");
    }
  }

  Future<void> addTextToChroma(String userId, String text) async {
    final url = Uri.parse('http://192.168.1.102:4000/api/store_to_chroma/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "text": text,
        }),
      );

      if (response.statusCode == 200) {
        print("Added text chunk to Chroma");
      } else {
        print("Failed to add text to Chroma: ${response.body}");
      }
    } catch (e) {
      print("Error adding text to Chroma: $e");
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBarOfSpokify(),
                  verticalSpace(100),
                  Text(
                    "Welcome",
                    style: MyFontStyle.font45Regular
                        .copyWith(color: MyColors.whiteColor, height: 1.0),
                  ),
                  Text(
                    "Back!",
                    style: MyFontStyle.font45Bold
                        .copyWith(color: MyColors.txt1Color, height: 1.0),
                  ),
                  verticalSpace(20),
                  MyTextFormField(
                    controller: emailController,
                    hint: "Email Address",
                    isObecure: false,
                    prefixIcon:
                    Icon(Icons.email_outlined, color: MyColors.fontColor),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  verticalSpace(20),
                  MyTextFormField(
                    controller: passwordController,
                    hint: "Password",
                    isObecure: !passwordVisible,
                    prefixIcon: Icon(Icons.lock, color: MyColors.fontColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: MyColors.fontColor,
                      ),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  verticalSpace(30),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomRaisedGradientButton(
                    onPressed: loginUser,
                    width: 350,
                    text: 'LOG IN',
                  ),
                  verticalSpace(20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.forget_password);
                    },
                    child: Text(
                      "Forgot Password?",
                      style: MyFontStyle.font11RegularUnderline.copyWith(
                        color: MyColors.whiteColor,
                        decoration: TextDecoration.underline,
                        decorationColor: MyColors.whiteColor,
                      ),
                    ),
                  ),
                  verticalSpace(10),
                  const DonotHaveAnAccountRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
