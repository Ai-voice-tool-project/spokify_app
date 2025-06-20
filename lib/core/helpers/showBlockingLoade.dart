import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showBlockingLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // المستخدم لا يستطيع إغلاقه
    builder: (_) => WillPopScope(
      onWillPop: () async => false,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );
}
void hideBlockingLoader(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
