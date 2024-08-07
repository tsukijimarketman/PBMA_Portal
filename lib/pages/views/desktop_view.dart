import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pbma_portal/TermsAndConditions/TAC_Web_View.dart';
import 'package:pbma_portal/pages/Auth_View/SignInDesktopView.dart';
import 'package:pbma_portal/widgets/text_reveal.dart';

class DesktopView extends StatefulWidget {
  const DesktopView({super.key});

  @override
  State<DesktopView> createState() => _DesktopViewState();
}

class _DesktopViewState extends State<DesktopView>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _textController;
  late AnimationController _textController2;
  late Animation<double> _textRevealAnimation;
  late Animation<double> _descriptionController;
  late Animation<double> _buttonController;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _quoteController;
  Color _appBarColor = Colors.transparent;

  @override
  void initState() {
    _textController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
      reverseDuration: Duration(milliseconds: 375),
    );
    _textController2 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
      reverseDuration: Duration(milliseconds: 375),
    );
    _textRevealAnimation = Tween<double>(begin: 100, end: 0).animate(
        CurvedAnimation(
            parent: _textController,
            curve: Interval(0.0, 0.3, curve: Curves.fastEaseInToSlowEaseOut)));
    _textOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _textController,
            curve: Interval(0.0, 0.3, curve: Curves.easeOut)));
    _descriptionController = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(
          parent: _textController,
          curve: Interval(0.3, 1, curve: Curves.easeOut)),
    );
    _quoteController = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(
          parent: _textController2,
          curve: Interval(0.0, 1, curve: Curves.easeOut)),
    );
    _buttonController = Tween<double>(begin: 0.0, end: 1).animate(
      CurvedAnimation(
          parent: _textController,
          curve: Interval(0.0, 1, curve: Curves.easeOut)),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    super.initState();
    Future.delayed(Duration(milliseconds: 1000), () {
      _textController.forward();
    });
    Future.delayed(Duration(milliseconds: 4000), () {
      _textController2.forward();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels > 0) {
      setState(() {
        _appBarColor = Colors.teal;
      });
    } else {
      setState(() {
        _appBarColor = Colors.transparent;
      });
    }
  }

  Color _textColor1 = Colors.white;
  Color _textColor2 = Colors.white;
  Color _textColor3 = Colors.white;
  Color _textColor5 = Colors.white;
  Color _textColor6 = Color.fromARGB(255, 1, 93, 168);

  final sectionKey1 = GlobalKey();
  final sectionKey2 = GlobalKey();
  final sectionKey3 = GlobalKey();

  bool _showSignInCard = false;
  bool _TAC = false;

  void scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(key.currentContext!,
        duration: Duration(seconds: 1), curve: Curves.easeInOut);
  }

  void toggleTAC() {
    setState(() {
      _TAC = !_TAC;
    });
  }

  void closeTAC() {
    setState(() {
      _TAC = false;
    });
  }

  void toggleSignInCard() {
    setState(() {
      _showSignInCard = !_showSignInCard;
    });
  }

  void closeSignInCard() {
    setState(() {
      _showSignInCard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      key: sectionKey1,
                      height: screenHeight,
                      width: screenWidth,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/campus.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth / 17),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(
                                87, 1, 93, 168), // Semi-transparent blue
                            Color.fromARGB(
                                255, 1, 93, 168), // Fully opaque blue
                          ],
                          stops: [0.5, 1.0],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.only(
                              left: screenWidth / 17,
                              right: screenWidth / 17,
                              top: 10),
                          height: screenHeight / 9,
                          width: screenWidth,
                        ),
                        SizedBox(
                          height: screenHeight / 6,
                        ),
                        Container(
                          width: 1000,
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth / 17),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextReveal(
                                  maxHeight: 60,
                                  textController: _textController,
                                  textOpacityAnimation: _textOpacityAnimation,
                                  textRevealAnimation: _textRevealAnimation,
                                  child: Text(
                                    "Prime Brilliant Minds Academy",
                                    style: TextStyle(
                                        fontFamily: "B",
                                        fontSize: screenHeight / 15,
                                        color: Colors.white),
                                  )),
                              SizedBox(
                                height: 20,
                              ),
                              FadeTransition(
                                opacity: _descriptionController,
                                child: Text(
                                  "TESDA Accredited Training and Assessment Center",
                                  style: TextStyle(
                                      fontFamily: "SB",
                                      fontSize: screenHeight / 27,
                                      color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              SizeTransition(
                                sizeFactor: _descriptionController,
                                axis: Axis.horizontal,
                                axisAlignment: -1.0,
                                child: Text(
                                  "Be a Dreamer, Achieve Greater, and be a PRIMER",
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontFamily: "L",
                                    fontSize: screenHeight / 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              MouseRegion(
                                onEnter: (_) {
                                  setState(() {
                                    _textColor5 = Colors.yellow;
                                    _textColor6 = Colors.black;
                                  });
                                },
                                onExit: (_) {
                                  setState(() {
                                    _textColor5 = Colors.white;
                                    _textColor6 =
                                        Color.fromARGB(255, 1, 93, 168);
                                  });
                                },
                                child: FadeTransition(
                                  opacity: _buttonController,
                                  child: Container(
                                    height: 50,
                                    width: 210,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStatePropertyAll(
                                                  _textColor5),
                                          shape: MaterialStatePropertyAll(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)))),
                                      onPressed: toggleTAC,
                                      child: Center(
                                          child: Text(
                                        "Get Started",
                                        style: TextStyle(
                                            color: _textColor6,
                                            fontFamily: "B",
                                            fontSize: 20),
                                      )),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _quoteController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _quoteController,
                            child: Container(
                              height: 90,
                              padding: EdgeInsets.symmetric(horizontal: 80),
                              width: MediaQuery.of(context).size.width,
                              color: Color.fromARGB(25, 158, 158, 158),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '" Education is about igniting a passion for learning and nurturing responsibility, integrity, and compassion in every student. "',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "SB",
                                      fontSize: (screenWidth / 85) + 2,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 25,
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(Icons.person,
                                              size: 20, color: Colors.black),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "LIGAYA C. TACBI,",
                                        style: TextStyle(
                                            fontFamily: "B",
                                            fontSize: (screenWidth / 85) + 2,
                                            color: Colors.white),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      SizedBox(height: 30),
                                      Text(
                                        "Ph.D (School Principal)",
                                        style: TextStyle(
                                            fontFamily: "M",
                                            fontSize: (screenWidth / 85) + 2,
                                            color: Colors.white),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                  key: sectionKey2,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Color.fromARGB(255, 1, 93, 168),
                  child: Column(
                    children: [],
                  ),
                ),
                Container(
                  key: sectionKey3,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Color.fromARGB(255, 1, 93, 168),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: AppBar(
                      toolbarHeight: screenWidth / 16,
                      elevation: 8,
                      backgroundColor: _appBarColor,
                      title: Container(
                        child: Row(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {},
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.asset(
                                      "assets/pbma.jpg",
                                      height: screenWidth / 20,
                                      width: screenWidth / 20,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "PBMA",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "B",
                                    fontSize: screenWidth / 50,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            MouseRegion(
                              onEnter: (_) {
                                setState(() {
                                  _textColor1 = Colors.yellow;
                                });
                              },
                              onExit: (_) {
                                setState(() {
                                  _textColor1 = Colors.white;
                                });
                              },
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  "Services",
                                  style: TextStyle(
                                    fontFamily: "SB",
                                    fontSize: 14,
                                    color: _textColor1,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 25),
                            MouseRegion(
                              onEnter: (_) {
                                setState(() {
                                  _textColor2 = Colors.yellow;
                                });
                              },
                              onExit: (_) {
                                setState(() {
                                  _textColor2 = Colors.white;
                                });
                              },
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  "About us",
                                  style: TextStyle(
                                    fontFamily: "SB",
                                    fontSize: 14,
                                    color: _textColor2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 25),
                            MouseRegion(
                              onEnter: (_) {
                                setState(() {
                                  _textColor3 = Colors.yellow;
                                });
                              },
                              onExit: (_) {
                                setState(() {
                                  _textColor3 = Colors.white;
                                });
                              },
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  "Contact us",
                                  style: TextStyle(
                                    fontFamily: "SB",
                                    fontSize: 14,
                                    color: _textColor3,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 25),
                            SizedBox(
                              width: screenWidth / 12,
                              height: screenWidth / 35,
                              child: TextButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.yellow),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                onPressed: toggleSignInCard,
                                child: Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontFamily: "B",
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 25),
                            SizedBox(
                              width: screenWidth / 12,
                              height: screenWidth / 35,
                              child: TextButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                onPressed: toggleTAC,
                                child: Text(
                                  "Enroll Now",
                                  style: TextStyle(
                                    fontFamily: "B",
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 1, 93, 168),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ));
              },
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 550),
            child: _showSignInCard
                ? Positioned.fill(
                    child: GestureDetector(
                      onTap: closeSignInCard,
                      child: Stack(
                        children: [
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child:
                                Container(color: Colors.black.withOpacity(0.5)),
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () {},
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                width: screenWidth / 1.2,
                                height: screenHeight / 1.2,
                                curve: Curves.easeInOut,
                                child: SignInDesktop(
                                  key: ValueKey('signInCard'),
                                  closeSignInCardCallback: closeSignInCard,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 550),
            child: _TAC
                ? Positioned.fill(
                    child: GestureDetector(
                      onTap: closeTAC,
                      child: Stack(
                        children: [
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child:
                                Container(color: Colors.black.withOpacity(0.5)),
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () {},
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                width: screenWidth / 1.2,
                                height: screenHeight / 1.2,
                                curve: Curves.easeInOut,
                                child: TACWebView(
                                  key: ValueKey('closeTAC'),
                                  closeTAC: closeTAC,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
