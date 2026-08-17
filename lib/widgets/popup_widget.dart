import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kboom/colors.dart';

class PersonalPopup extends StatefulWidget {
  const PersonalPopup({super.key});

  static testFunction(BuildContext context) async {
    return await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        barrierColor: context.modalOverlayColor,
        builder: (context) {
          return Text("AAAAAA");
        },
    );
  }

  @override
  State<PersonalPopup> createState() => _PersonalPopupState();
}

class _PersonalPopupState extends State<PersonalPopup> {
  @override
  Widget build(BuildContext context) {
    return Text("Ceci est une popup !");
  }
}
