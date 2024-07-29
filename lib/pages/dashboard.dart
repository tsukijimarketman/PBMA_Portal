import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pbma_portal/pages/views/desktop_view.dart';
import 'package:pbma_portal/pages/views/mobile_view.dart'; 

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 600;
  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isDesktop(context) ? DesktopView() : MobileView(), // Conditionally render the view
    );
  }
}
