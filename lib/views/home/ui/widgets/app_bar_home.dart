import 'package:flutter/material.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theming/my_colors.dart';
import '../../../../core/theming/my_fonts.dart';
import '../screens/SearchResultScreen.dart';

class AppBarHome extends StatelessWidget implements PreferredSizeWidget {
  const AppBarHome({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.userProfile);
        },
        icon: const Icon(
          Icons.person_outlined,
          color: MyColors.button1Color,
          size: 35,
        ),
      ),
      title: Text(
        "Spokify",
        style: MyFontStyle.font28Regular.copyWith(color: MyColors.whiteColor),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AskQuestionPage()),
            );
          },
          icon: const Icon(
            Icons.search,
            color: MyColors.button1Color,
            size: 35,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
