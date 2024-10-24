import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class StudentUI extends StatefulWidget {
  const StudentUI({super.key});

  @override
  State<StudentUI> createState() => _StudentUIState();
}

class _StudentUIState extends State<StudentUI> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  // Declare the selectedSemester variable
  String selectedSemester = 'SELECT SEMESTER';

  // Store grade inputs in a Map
  final Map<String, TextEditingController> gradeControllers = {
    'subject1': TextEditingController(),
    'subject2': TextEditingController(),
    'subject3': TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      key: _key,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: canvasColor,
              title: Text(
                "Student Dashboard",
                style: TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                onPressed: () {
                  _key.currentState?.openDrawer();
                },
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      drawer: ExampleSidebarX(controller: _controller),
      body: Row(
        children: [
          if (!isSmallScreen) ExampleSidebarX(controller: _controller),
          Expanded(
            child: Center(
              // Pass selectedSemester and onSemesterChanged to _ScreensExample
              child: _ScreensExample(
                controller: _controller,
                selectedSemester: selectedSemester,
                onSemesterChanged: (newValue) {
                  setState(() {
                    selectedSemester = newValue;
                  });
                },
                gradeControllers: gradeControllers, // Pass the grade controllers
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExampleSidebarX extends StatelessWidget {
  const ExampleSidebarX({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 1, 93, 168),
      child: SidebarX(
        controller: _controller,
        theme: SidebarXTheme(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: canvasColor,
            borderRadius: BorderRadius.circular(20),
          ),
          hoverColor: scaffoldBackgroundColor,
          textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          selectedTextStyle: const TextStyle(color: Colors.white),
          hoverTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          itemTextPadding: const EdgeInsets.only(left: 30),
          selectedItemTextPadding: const EdgeInsets.only(left: 30),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: canvasColor),
          ),
          selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: actionColor.withOpacity(0.37),
            ),
            gradient: const LinearGradient(
              colors: [accentCanvasColor, canvasColor],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 30,
              )
            ],
          ),
          iconTheme: IconThemeData(
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          selectedIconTheme: const IconThemeData(
            color: Colors.white,
            size: 20,
          ),
        ),
        extendedTheme: const SidebarXTheme(
          width: 200,
          decoration: BoxDecoration(
            color: canvasColor,
          ),
        ),
        footerDivider: divider,
        headerBuilder: (context, extended) {
          return SizedBox(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset('assets/avatar.png'),
                ),
                if (extended)
                  Text(
                    "2024-PBMA-0011",
                    style: TextStyle(color: Colors.white),
                  ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          );
        },
        items: [
          SidebarXItem(
            icon: Icons.home,
            label: 'Home',
          ),
          const SidebarXItem(
            icon: Icons.assessment_sharp,
            label: 'View Grades',
          ),
          const SidebarXItem(
            icon: Icons.how_to_reg_sharp,
            label: 'Check Enrollment',
          ),
          SidebarXItem(
            icon: Icons.lock,
            label: 'Change Password',
          ),
          const SidebarXItem(
            icon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _ScreensExample extends StatelessWidget {
  const _ScreensExample({
    Key? key,
    required this.controller,
    required this.selectedSemester,
    required this.onSemesterChanged,
    required this.gradeControllers,
  }) : super(key: key);

  final SidebarXController controller;
  final String selectedSemester;
  final ValueChanged<String> onSemesterChanged;
  final Map<String, TextEditingController> gradeControllers;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pageTitle = _getTitleByIndex(controller.selectedIndex);
        switch (controller.selectedIndex) {
          case 0:
            return Container(
              color: Color.fromARGB(255, 1, 93, 168),
              child: Center(
                child: Text("Home"),
              ),
            );
          case 1:
            return Container(
            padding: EdgeInsets.all(16.0),
            color: Color.fromARGB(255, 1, 93, 168),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  'REPORT CARD',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                  ),
                ),
                SizedBox(height: 20), 

                
                Container(
                  width: 200, 
                  height: 30,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSemester,
                    items: ['SELECT SEMESTER', 'First Semester', 'Second Semester']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      onSemesterChanged(newValue!);
                    },
                    underline: SizedBox(),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  color: Colors.white, 
                  child: Table(
                    border: TableBorder.all(color: Colors.black), 
                    columnWidths: {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(4), // Adjust for balanced column width
                      2: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Course Code', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Subject', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Grade', style: TextStyle(color: Colors.black)),
                        ),
                      ]),
                      // First subject row
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('COURSE001', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Subject 1', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            gradeControllers['subject1']?.text ?? 'N/A',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ]),
                      // Second subject row
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('COURSE002', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Subject 2', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            gradeControllers['subject2']?.text ?? 'N/A',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ]),
                      // Third subject row
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('COURSE003', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Subject 3', style: TextStyle(color: Colors.black)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            gradeControllers['subject3']?.text ?? 'N/A',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                        onPressed: () {
                          // Handle finalizing grades (e.g., validation)
                          print('Grades finalized:');
                          gradeControllers.forEach((key, controller) {
                            print('$key: ${controller.text}');
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color.fromARGB(255, 1, 93, 168), 
                          backgroundColor: Colors.white, 
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: Size(80, 20),
                        ),
                        child: Text('Finalize', style: TextStyle(fontSize: 10),),
                      ),
                        SizedBox(width: 10),
                        Text(
                          'Note: You can only finalize this \nwhen the subject is completed.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),

                    // Print Result button aligned to the right
                    ElevatedButton(
                      onPressed: () {
                        // Handle print result functionality here
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, 
                        backgroundColor: Colors.yellow, 
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12), 
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5), 
                          ),
                      ),
                      child: Text('Print Result'),
                    ),
                  ],
                ),
              ],
            ),
          );
          case 2:
            return Container(
              color: Color.fromARGB(255, 1, 93, 168),
              child: Center(
                child: Text("Check Enrollment"),
              ),
            );
          case 3:
            return Container(
              color: Color.fromARGB(255, 1, 93, 168),
              child: Center(
                child: Text("Change Password"),
              ),
            );
          case 4:
            return Container(
              color: Color.fromARGB(255, 1, 93, 168),
              child: Center(
                child: Text("Settings"),
              ),
            );
          default:
            return Text(
              pageTitle,
              style: theme.textTheme.headlineSmall,
            );
        }
      },
    );
  }

  String _getTitleByIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'View Grades';
      case 2:
        return 'Check Enrollment';
      case 3:
        return 'Change Password';
      case 4:
        return 'Settings';
      default:
        return 'Not found page';
    }
  }
}

// Your colors here, replace with actual color values if needed
const canvasColor = Color(0xFF1D3557);
const scaffoldBackgroundColor = Color(0xFF457B9D);
const accentCanvasColor = Color(0xFFA8DADC);
const actionColor = Color(0xFFF4A261);
const divider = Divider(color: Colors.white54, thickness: 1);
