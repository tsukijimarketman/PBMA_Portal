import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pbma_portal/student_utils/cases/case0.dart';
import 'package:pbma_portal/widgets/hover_extensions.dart';
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
                gradeControllers:
                    gradeControllers, // Pass the grade controllers
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExampleSidebarX extends StatefulWidget {
  const ExampleSidebarX({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  @override
  State<ExampleSidebarX> createState() => _ExampleSidebarXState();
}

class _ExampleSidebarXState extends State<ExampleSidebarX> {
  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  String? _studentId;
  String? _imageUrl; // Variable to store the student's image URL

  Future<void> _loadStudentData() async {
    User? user =
        FirebaseAuth.instance.currentUser; // Get the current logged-in user

    if (user != null) {
      try {
        // Query the 'users' collection where the 'uid' field matches the current user's UID
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          // Assuming only one document will be returned, get the first document
          DocumentSnapshot userDoc = userSnapshot.docs.first;

          setState(() {
            _studentId = userDoc['student_id'];
            _imageUrl = userDoc['image_url'];
          });
        } else {
          print('No matching student document found.');
        }
      } catch (e) {
        print('Failed to load student data: $e');
      }
    } else {
      print('User is not logged in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 1, 93, 168),
      child: SidebarX(
        controller: widget._controller,
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
                  child: CircleAvatar(
                    radius: 100,
                    backgroundImage: _imageUrl != null
                        ? NetworkImage(
                            _imageUrl!) // Use _imageUrl directly as a String
                        : NetworkImage(
                            'https://cdn4.iconfinder.com/data/icons/linecon/512/photo-512.png'),
                  ),
                ),
                if (extended)
                  Text(
                    _studentId ?? "No ID", // Display student ID if available
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
          const SidebarXItem(
            icon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _ScreensExample extends StatefulWidget {
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
  State<_ScreensExample> createState() => _ScreensExampleState();
}

class _ScreensExampleState extends State<_ScreensExample> {
  List<String> _sections = [];
  List<Map<String, dynamic>> _subjects = []; // To store the fetched subjects

  String? _studentId;
  String? _fullName;
  String? _strand;
  String? _track;
  String? _gradeLevel;
  String? _semester;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _fetchSections();
    _loadStudentData();
  }

  Future<void> _fetchSections() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('sections').get();
    setState(() {
      _sections = snapshot.docs
          .map((doc) => doc['section_name'] as String)
          .toList(); // Adjust the field name as necessary
    });
  }

  Future<void> _loadStudentData() async {
    User? user =
        FirebaseAuth.instance.currentUser; // Get the current logged-in user

    if (user != null) {
      try {
        // Query the 'users' collection where the 'uid' field matches the current user's UID
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          // Assuming only one document will be returned, get the first document
          DocumentSnapshot userDoc = userSnapshot.docs.first;

          setState(() {
            _studentId = userDoc['student_id'];
            _fullName =
                '${userDoc['first_name']} ${userDoc['middle_name'] ?? ''} ${userDoc['last_name']} ${userDoc['extension_name'] ?? ''}'
                    .trim();
            _strand = userDoc['seniorHigh_Strand'];
            _track = userDoc['seniorHigh_Track'];
            _gradeLevel = userDoc['grade_level'];
            _semester = userDoc['semester'];
          });
        } else {
          print('No matching student document found.');
        }
      } catch (e) {
        print('Failed to load student data: $e');
      }
    } else {
      print('User is not logged in.');
    }
  }

  Future<void> _saveSection() async {
    if (_selectedSection != null && _selectedSection!.isNotEmpty) {
      try {
        // Get the currently logged-in user
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Query Firestore for the document where 'uid' matches the logged-in user's UID
          QuerySnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('uid', isEqualTo: user.uid)
              .get();

          // Check if any documents were returned
          if (userSnapshot.docs.isNotEmpty) {
            // Assuming 'uid' is unique, take the first document
            DocumentSnapshot userDoc = userSnapshot.docs.first;

            // Update the 'section' field in the user's document
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userDoc.id)
                .update({
              'section': _selectedSection,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Section saved successfully!')),
            );
          } else {
            print('No document found for the current user.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User document not found.')),
            );
          }
        } else {
          print('No user is logged in.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'No user is logged in. Please log in to save the section.')),
          );
        }
      } catch (e) {
        print('Error saving section: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving section: $e')),
        );
      }
    } else {
      // Show an error message if no section is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a section before saving.')),
      );
    }
  }

  Future<void> _loadSubjects() async {
    if (_selectedSection != null) {
      try {
        // Fetch the selected section's document
        QuerySnapshot sectionSnapshot = await FirebaseFirestore.instance
            .collection('sections')
            .where('section_name', isEqualTo: _selectedSection)
            .get();

        if (sectionSnapshot.docs.isNotEmpty) {
          DocumentSnapshot sectionDoc = sectionSnapshot.docs.first;
          String sectionSemester = sectionDoc[
              'semester']; // Assuming 'semester' field exists in 'sections'

          // Query subjects that have the same semester as the selected section
          QuerySnapshot subjectSnapshot = await FirebaseFirestore.instance
              .collection('subjects')
              .where('semester', isEqualTo: sectionSemester)
              .get();

          setState(() {
            // Store the fetched subjects
            _subjects = subjectSnapshot.docs
                .map((doc) => {
                      'subject_code': doc[
                          'subject_code'], // Adjust field names if necessary
                      'subject_name': doc['subject_name'],
                      'category':
                          doc['category'], // Assuming 'grade' field exists
                    })
                .toList();
          });

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subjects loaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No matching section found.')),
          );
        }
      } catch (e) {
        print('Error loading subjects: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select a section before loading subjects.')),
      );
    }
  }

  String? _imageUrl;

  Future<void> _imageGetterFromExampleState() async {
    User? user =
        FirebaseAuth.instance.currentUser; // Get the current logged-in user

    if (user != null) {
      try {
        // Query the 'users' collection where the 'uid' field matches the current user's UID
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          // Assuming only one document will be returned, get the first document
          DocumentSnapshot userDoc = userSnapshot.docs.first;

          setState(() {
            _imageUrl = userDoc['image_url'];
          });
        } else {
          print('No matching student document found.');
        }
      } catch (e) {
        print('Failed to load student data: $e');
      }
    } else {
      print('User is not logged in.');
    }
  }

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final pageTitle = _getTitleByIndex(widget.controller.selectedIndex);
        switch (widget.controller.selectedIndex) {
          case 0:
            return Case0();
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
                      value: widget.selectedSemester,
                      items: [
                        'SELECT SEMESTER',
                        'First Semester',
                        'Second Semester'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        widget.onSemesterChanged(newValue!);
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
                        1: FlexColumnWidth(
                            4), // Adjust for balanced column width
                        2: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(children: [
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Course Code',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Subject',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Grade',
                                style: TextStyle(color: Colors.black)),
                          ),
                        ]),
                        // First subject row
                        TableRow(children: [
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('COURSE001',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Subject 1',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              widget.gradeControllers['subject1']?.text ??
                                  'N/A',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ]),
                        // Second subject row
                        TableRow(children: [
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('COURSE002',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Subject 2',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              widget.gradeControllers['subject2']?.text ??
                                  'N/A',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ]),
                        // Third subject row
                        TableRow(children: [
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('COURSE003',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Subject 3',
                                style: TextStyle(color: Colors.black)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              widget.gradeControllers['subject3']?.text ??
                                  'N/A',
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
                              widget.gradeControllers
                                  .forEach((key, controller) {
                                print('$key: ${controller.text}');
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Color.fromARGB(255, 1, 93, 168),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              minimumSize: Size(80, 20),
                            ),
                            child: Text(
                              'Finalize',
                              style: TextStyle(fontSize: 10),
                            ),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Student Data",
                        style: TextStyle(color: Colors.white, fontSize: 24)),
                    SizedBox(height: 20),
                    Text('Student ID no: ${_studentId ?? ''}',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    Text('Student Full Name: ${_fullName ?? ''}',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    Text('Strand: ${_strand ?? ''}',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    Text('Track: ${_track ?? ''}',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    Text('Grade Level: ${_gradeLevel ?? ''}',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    Text('Semester: ${_semester ?? ''}',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    Text("Subjects",
                        style: TextStyle(color: Colors.white, fontSize: 24)),
                    DropdownButton<String>(
                      value: _selectedSection,
                      hint: Text('Select a section',
                          style: TextStyle(color: Colors.white)),
                      items: _sections.map((String section) {
                        return DropdownMenuItem<String>(
                          value: section,
                          child: Text(section,
                              style: TextStyle(
                                  color: Colors.black)), // Section name
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSection =
                              newValue; // Update selected section
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveSection, // Call the save function
                      child: Text('Save Section'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _loadSubjects, child: Text('Load Subjects')),
                    _subjects.isNotEmpty
                        ? Table(
                            border: TableBorder.all(color: Colors.black),
                            columnWidths: {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(
                                  4), // Adjust for balanced column width
                              2: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('Course Code',
                                      style: TextStyle(color: Colors.black)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('Subject',
                                      style: TextStyle(color: Colors.black)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('Grade',
                                      style: TextStyle(color: Colors.black)),
                                ),
                              ]),
                              // Dynamically create rows based on the fetched subjects
                              ..._subjects.map((subject) {
                                return TableRow(children: [
                                  Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(subject['subject_code'],
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(subject['subject_name'],
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(subject['category'] ?? 'N/A',
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                ]);
                              }).toList(),
                            ],
                          )
                        : Text('No subjects available',
                            style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );

          case 3:
            return Container(
              color: Color.fromARGB(255, 1, 93, 168),
              height: screenHeight,
              width: screenWidth,
              child: Container(
                margin: EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: MouseRegion(
                            onEnter: (_) {
                              setState(() {
                                _isHovered = true;
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                _isHovered = false;
                              });
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 90,
                                  backgroundImage: _imageUrl != null
                                      ? NetworkImage(_imageUrl!)
                                      : NetworkImage(
                                          'https://cdn4.iconfinder.com/data/icons/linecon/512/photo-512.png'),
                                ),
                                if (_isHovered) // Show icon only on hover
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gerick M. Velasquez",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "B",
                                  fontSize: 30),
                            ),
                            SizedBox(height: 5),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                height: 40,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "Edit Profile",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: "B",
                                        fontSize: 15),
                                  ),
                                ),
                              ),
                            ).showCursorOnHover,
                          ],
                        )
                      ],
                    ),
                  ],
                ),
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