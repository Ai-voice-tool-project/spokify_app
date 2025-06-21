import 'package:flutter/material.dart';
import 'package:gradprj/core/helpers/custom_raised_gradientbutton.dart';
import 'package:gradprj/core/helpers/divider_widget.dart';
import 'package:gradprj/core/helpers/spacing.dart';
import 'package:gradprj/core/routing/routes.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import 'package:gradprj/core/theming/my_fonts.dart';
import 'package:gradprj/views/getStarted/widgets/app_bar_get_started.dart';
import 'package:gradprj/views/getStarted/widgets/social_media.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/back.png', // تأكد من كتابة المسار صحيح
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 40),
              ),
              verticalSpace(180),
              Text(
                "Let’s Get",
                style: MyFontStyle.font45Regular
                    .copyWith(color: MyColors.whiteColor, height: 1.0),
              ),
              Text("Started!",
                  style: MyFontStyle.font45Bold
                      .copyWith(color: MyColors.txt1Color, height: 1.0)),
              verticalSpace(120),
              CustomRaisedGradientButton(
                text: 'SIGN IN',
                width: 250,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.login);
                },
              ),
              verticalSpace(130),
              const DividerWidget(
                color: MyColors.whiteColor,
                height: 20,
              ),
              verticalSpace(20),
              Text(
                "DIDN'T HAVE ACCOUNT?",
                style: MyFontStyle.font13RegularAcc
                    .copyWith(color: MyColors.whiteColor),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.singUp);  // غير "signUp" إلى اسم الطريق الصحيح
                },
                child: Text(
                  "SING UP NOW",
                  style: MyFontStyle.font13RegularAcc
                      .copyWith(color: MyColors.txt2Color),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
}
