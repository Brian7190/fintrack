import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

class GoogleCalendarConnectButton extends StatelessWidget {
  const GoogleCalendarConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return web.renderButton();
  }
}
