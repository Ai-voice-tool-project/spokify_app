import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// استبدل الحاجات دي باللي عندك لو مختلفين
import 'package:gradprj/core/helpers/app_bar.dart';
import 'package:gradprj/core/helpers/custom_raised_gradientbutton.dart';
import 'package:gradprj/core/helpers/spacing.dart';
import 'package:gradprj/core/routing/routes.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import 'package:gradprj/core/theming/my_fonts.dart';
import 'package:gradprj/core/widgets/text_form_field.dart';
import 'package:gradprj/views/sing_up/ui/widgets/alreadyhaveanaccount.dart';

import '../../../../core/helpers/ipconfig.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  // حالة عرض/إخفاء كلمة المرور
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://$ipAddress:4000/api/v1/auth/register');

    final Map<String, String> body = {
      "userName": usernameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // تسجيل ناجح - توجه للصفحة الرئيسية
        Navigator.pushNamed(context, Routes.login);
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'Registration failed';
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

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBarOfSpokify(),
                  verticalSpace(60),
                  Text(
                    "Create an ",
                    style: MyFontStyle.font45Regular
                        .copyWith(color: MyColors.whiteColor, height: 1.0),
                  ),
                  Text(
                    "Account!",
                    style: MyFontStyle.font45Bold
                        .copyWith(color: MyColors.txt1Color, height: 1.0),
                  ),
                  verticalSpace(40),
                  MyTextFormField(
                    controller: emailController,
                    hint: "Email Address",
                    isObecure: false,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: MyColors.fontColor,
                    ),
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
                    controller: usernameController,
                    hint: "Username",
                    isObecure: false,
                    prefixIcon: Icon(
                      Icons.person,
                      color: MyColors.fontColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
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
                        passwordVisible ? Icons.visibility : Icons.visibility_off,
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
                        return 'Password should be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  verticalSpace(20),
                  MyTextFormField(
                    controller: confirmPasswordController,
                    hint: "Confirm Password",
                    isObecure: !confirmPasswordVisible,
                    prefixIcon: Icon(Icons.lock, color: MyColors.fontColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: MyColors.fontColor,
                      ),
                      onPressed: () {
                        setState(() {
                          confirmPasswordVisible = !confirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm password';
                      }
                      return null;
                    },
                  ),
                  verticalSpace(30),
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : CustomRaisedGradientButton(
                    onPressed: registerUser,
                    width: 350,
                    text: "SIGN UP",
                  ),
                  verticalSpace(20),
                  const AlreadyHaveAnAccount(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
