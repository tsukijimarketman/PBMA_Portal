// ignore_for_file: unused_element

import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbma_portal/launcher.dart';
import 'package:pbma_portal/student_utils/cases/case0.dart';
import 'package:pbma_portal/student_utils/cases/case2.dart';
import 'package:pbma_portal/widgets/hover_extensions.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:pdf/widgets.dart' as pw;

class StudentUI extends StatefulWidget {
  const StudentUI({super.key});

  @override
  State<StudentUI> createState() => _StudentUIState();
}

class _StudentUIState extends State<StudentUI> {
  final SidebarXController _sidebarController =
      SidebarXController(selectedIndex: 0);
  final ValueNotifier<String?> _imageNotifier = ValueNotifier<String?>(null);
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late SharedPreferences prefs;

  String selectedSemester = 'SELECT SEMESTER';

  @override
  void initState() {
    super.initState();
    _loadInitialProfileImage();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('sidebar_index') ?? 0;
    setState(() {
      _sidebarController.selectIndex(savedIndex);
    });

    // Add listener to save index when it changes
    _sidebarController.addListener(() {
      prefs.setInt('sidebar_index', _sidebarController.selectedIndex);
    });
  }

  Future<void> _loadInitialProfileImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final docSnapshot = await userDoc.get();
      final imageUrl = docSnapshot.data()?['image_url'];
      _imageNotifier.value = imageUrl; // Set initial profile picture URL
    }
  }

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
      drawer: isSmallScreen
          ? ExampleSidebarX(
              controller: _sidebarController,
              imageNotifier: _imageNotifier, // Pass imageNotifier here
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen)
            ExampleSidebarX(
              controller: _sidebarController,
              imageNotifier: _imageNotifier, // Pass imageNotifier here as well
            ),
          Expanded(
            child: Center(
              child: _ScreensExample(
                controller: _sidebarController,
                selectedSemester: selectedSemester,
                onSemesterChanged: (newValue) {
                  setState(() {
                    selectedSemester = newValue;
                  });
                },
                imageNotifier:
                    _imageNotifier, // Pass imageNotifier to _ScreensExample
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
    required this.imageNotifier,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;
  final ValueNotifier<String?> imageNotifier;

  @override
  State<ExampleSidebarX> createState() => _ExampleSidebarXState();
}

class _ExampleSidebarXState extends State<ExampleSidebarX> {
  @override
  void initState() {
    super.initState();
    _loadStudentData();

    // Listen to changes in imageNotifier
    widget.imageNotifier.addListener(() {
      setState(() {}); // Rebuild when imageNotifier updates
    });
  }

  String? _studentId;
  String? _imageUrl; // Variable to store the student's image URL

  Future<void> _loadStudentData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;

          setState(() {
            _studentId = userDoc['student_id'];
            widget.imageNotifier.value = userDoc['image_url'];
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
                    backgroundImage: widget.imageNotifier.value != null
                        ? NetworkImage(widget.imageNotifier.value!)
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
    required this.imageNotifier,
  }) : super(key: key);

  final SidebarXController controller;
  final String selectedSemester;
  final ValueChanged<String> onSemesterChanged;
  final ValueNotifier<String?> imageNotifier;

  @override
  State<_ScreensExample> createState() => _ScreensExampleState();
}

class _ScreensExampleState extends State<_ScreensExample> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey for form validation
  List<String> _sections = [];
  List<Map<String, dynamic>> _subjects = []; // To store the fetched subjects

  TextEditingController houseNumberController = TextEditingController();
  TextEditingController streetNameController = TextEditingController();
  TextEditingController subdivisionBarangayController = TextEditingController();
  TextEditingController cityMunicipalityController = TextEditingController();
  TextEditingController provinceController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController cellphoneNumController = TextEditingController();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureTextNew = true;
  bool _obscureTextConfirm = true;
  bool _passwordMismatch = false;

  String? _studentId;
  String? _fullName;
  late String _strand;
  String? _track;
  String? _gradeLevel;
  String? _semester;
  String? _selectedSection;
  String? _enrollmentStatus;
  Map<String, dynamic> userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Call all necessary functions during widget initialization
    _initializeData();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    phoneController.dispose();
    houseNumberController.dispose();
    streetNameController.dispose();
    subdivisionBarangayController.dispose();
    cityMunicipalityController.dispose();
    provinceController.dispose();
    countryController.dispose();
    cellphoneNumController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Wait for all data loading functions to complete
      await Future.wait([
        _fetchUserData(),
        _fetchSections(),
        _loadStudentData(),
        _imageGetterFromExampleState(),
        _loadSubjects(),
        _fetchEnrollmentStatus(),
        _checkEnrollmentStatus(),
        _fetchSavedSectionData()      
        ]);
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Modify _fetchUserData to return a Future
  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docSnapshot = querySnapshot.docs.first;
          if (mounted) {
            setState(() {
              userData = docSnapshot.data() as Map<String, dynamic>;
              // Initialize controllers with fetched data
              houseNumberController.text = userData['house_number'] ?? '';
              streetNameController.text = userData['street_name'] ?? '';
              subdivisionBarangayController.text =
                  userData['subdivision_barangay'] ?? '';
              cityMunicipalityController.text =
                  userData['city_municipality'] ?? '';
              provinceController.text = userData['province'] ?? '';
              countryController.text = userData['country'] ?? '';
              phoneController.text = userData['phone_number'] ?? '';
              cellphoneNumController.text = userData['cellphone_number'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_newPasswordController.text.isNotEmpty ||
            _confirmPasswordController.text.isNotEmpty) {
          if (_newPasswordController.text != _confirmPasswordController.text) {
            setState(() {
              _passwordMismatch = true;
            });
            // Add a ScaffoldMessenger to show the error more prominently
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                    Text('Passwords do not match'),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
            return; // Return early if passwords don't match
          }
          setState(() {
            _passwordMismatch = false;
          });
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('uid', isEqualTo: user.uid)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final docSnapshot = querySnapshot.docs.first;

            // Check if any user data fields have been modified
            bool hasUserDataChanges = houseNumberController.text.isNotEmpty ||
                streetNameController.text.isNotEmpty ||
                subdivisionBarangayController.text.isNotEmpty ||
                cityMunicipalityController.text.isNotEmpty ||
                provinceController.text.isNotEmpty ||
                countryController.text.isNotEmpty ||
                phoneController.text.isNotEmpty ||
                cellphoneNumController.text.isNotEmpty;

            // Check if password fields have been filled
            bool hasPasswordChanges = _newPasswordController.text.isNotEmpty &&
                _confirmPasswordController.text.isNotEmpty;

            // Update user data if changes exist
            if (hasUserDataChanges) {
              await docSnapshot.reference.update({
                'house_number': houseNumberController.text,
                'street_name': streetNameController.text,
                'subdivision_barangay': subdivisionBarangayController.text,
                'city_municipality': cityMunicipalityController.text,
                'province': provinceController.text,
                'country': countryController.text,
                'phone_number': phoneController.text,
                'cellphone_number': cellphoneNumController.text
              });
            }

            // Update password if changes exist
            if (hasPasswordChanges) {
              if (_newPasswordController.text !=
                  _confirmPasswordController.text) {
                setState(() {
                  _passwordMismatch = true;
                });
                return;
              }

              // Password validation
              RegExp passwordRegex = RegExp(
                r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~_-]).{8,}$',
              );

              if (!passwordRegex.hasMatch(_newPasswordController.text)) {
                _showDialog('Weak Password',
                    'Password must contain at least 8 characters, including uppercase letters, lowercase letters, numbers, and symbols.');
                return;
              }

              await user.updatePassword(_newPasswordController.text);

              // Clear password fields after successful update
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              setState(() {
                _passwordMismatch = false;
              });
            }

            // Show success message
            if (hasUserDataChanges || hasPasswordChanges) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                      Text(hasUserDataChanges && hasPasswordChanges
                          ? "Information and password updated successfully"
                          : hasUserDataChanges
                              ? "Information updated successfully"
                              : "Password updated successfully"),
                    ],
                  ),
                ),
              );
            }

            // Refresh user data
            if (hasUserDataChanges) {
              _fetchUserData();
            }
          }
        }
      } catch (e) {
        print("Error updating: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
              Text("Error updating: $e"),
            ],
          )),
        );
      }
    }
  }

  void _showDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(
                'OK',
                style: TextStyle(color: Colors.blueAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchEnrollmentStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Handle user not logged in

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1) // Assuming there's one document per user
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        setState(() {
          // Assuming enrollment_status is a field in your document
          _enrollmentStatus = docSnapshot.docs.first['enrollment_status'];
          // Also fetch other student details if needed
          _studentId = docSnapshot.docs.first['student_id'];
          _fullName = docSnapshot.docs.first['full_name'];
          _strand = docSnapshot.docs.first['strand'];
          _track = docSnapshot.docs.first['track'];
          _gradeLevel = docSnapshot.docs.first['grade_level'];
          _semester = docSnapshot.docs.first['semester'];
        });
      }
    } catch (e) {
      // Handle errors (e.g., network issues)
      print('Error fetching enrollment status: $e');
    }
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

          // Load grades based on the selected semester
          await _loadGrades();
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

  Map<String, List<Map<String, String>>> semesterGrades = {};

  // Case 1
  Future<void> _loadGrades() async {
    try {
      List<String> collectionsToCheck = [
        'Grade 11 - 1st Semester',
        'Grade 11 - 2nd Semester',
        'Grade 12 - 1st Semester',
        'Grade 12 - 2nd Semester',
      ];

      // Clear previous grades
      semesterGrades.clear(); // Make sure to clear previous data

      // Loop through collections to fetch grades
      for (String collectionName in collectionsToCheck) {
        QuerySnapshot gradeSnapshot =
            await FirebaseFirestore.instance.collection(collectionName).get();

        print('Checking collection: $collectionName');

        if (gradeSnapshot.docs.isNotEmpty) {
          List<Map<String, String>> gradesList =
              []; // Temporary list for grades in this semester

          for (var gradeDoc in gradeSnapshot.docs) {
            var studentData = gradeDoc.data() as Map<String, dynamic>;

            // Loop through each student in the document
            studentData.forEach((studentKey, studentValue) {
              // Get the list of grades for the student
              List<dynamic> gradesListFromDoc = studentValue['grades'] ?? [];

              // Check each grade entry for matching UID
              for (var gradeEntry in gradesListFromDoc) {
                if (gradeEntry is Map<String, dynamic>) {
                  String uid = gradeEntry['uid'] ??
                      ''; // Get the uid from the grade entry

                  // Check if the uid matches the current user's uid
                  if (uid == FirebaseAuth.instance.currentUser?.uid) {
                    String subjectCode = gradeEntry['subject_code'] ?? '';
                    String subjectName = gradeEntry['subject_name'] ?? '';
                    String grade = gradeEntry['grade']?.toString() ?? '';

                    // Add to temporary grades list
                    gradesList.add({
                      'subject_code': subjectCode,
                      'subject_name': subjectName,
                      'grade': grade,
                    });

                    print('Added grade: $grade for subject: $subjectName');
                  }
                }
              }
            });
          }

          if (gradesList.isNotEmpty) {
            semesterGrades[collectionName] =
                gradesList; // Save to the semesterGrades map
          }
        }
      }

      setState(() {
        // Update UI
      });

      if (semesterGrades.isEmpty) {
        print('No grades found for the current user UID across all semesters.');
      }
    } catch (e) {
      print('Error loading grades: $e');
    }
  }

  // Case 1

  // Case 2
  // Add this new method to fetch saved data
  Future<void> _checkEnrollmentStatus() async {
  try {
    // Get the active configuration
    QuerySnapshot activeConfig = await FirebaseFirestore.instance
        .collection('configurations')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (activeConfig.docs.isNotEmpty) {
      String configId = activeConfig.docs.first.id;
      
      // Get the user's current enrollment data
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Cast the data to Map<String, dynamic>
        final userData = userDoc.data() as Map<String, dynamic>;

        // Check if the user needs to re-enroll
        if (userData['enrollment_status'] == 're-enrolled') {
          // Show re-enrollment UI
          setState(() {
            _isFinalized = false;
            _selectedSection = null;
            _subjects.clear();
          });
        }
      }
    }
  } catch (e) {
    print('Error checking enrollment status: $e');
  }
}

Future<void> _fetchSavedSectionData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      final userDocId = userDoc.docs.first.id;
      
      // Get the sections subcollection document
      final sectionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .collection('sections')
          .doc(userDocId)
          .get();

      if (sectionDoc.exists) {
        final data = sectionDoc.data();
        setState(() {
          _selectedSection = data?['selectedSection'];
          _subjects = List<Map<String, dynamic>>.from(data?['subjects'] ?? []);
          _isFinalized = data?['isFinalized'] ?? false;
        });
      }
    }
  } catch (e) {
    print('Error fetching saved section data: $e');
  }
}

  Future<void> _saveandfinalization() async {
    if (_selectedSection != null) {
      try {
        await _saveSection();
        await _finalizeSelection();
        setState(() {}); // Update UI to show loaded subjects
      } catch (e) {
        print('Error saving and loading subjects: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
              Text('Error saving and loading subjects: $e'),
            ],
          )),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(
          children: [
            Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
            Text('Please select a section first.'),
          ],
        )),
      );
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
            DocumentSnapshot userDoc = userSnapshot.docs.first;

            // Fetch the selected section document
            QuerySnapshot sectionSnapshot = await FirebaseFirestore.instance
                .collection('sections')
                .where('section_name', isEqualTo: _selectedSection)
                .get();

            // Check if any section documents were returned
            if (sectionSnapshot.docs.isNotEmpty) {
              DocumentSnapshot sectionDoc = sectionSnapshot.docs.first;

              // Update the 'section' field in the user's document
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userDoc.id)
                  .update({
                'section': _selectedSection,
              });

              // No need to increment capacityCount anymore

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Row(
                  children: [
                    Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                    Text('Section saved successfully!'),
                  ],
                )),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Row(
                  children: [
                    Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                    Text('Section document not found.'),
                  ],
                )),
              );
            }
          } else {
            print('No document found for the current user.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Row(
                children: [
                  Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                  Text('User document not found.'),
                ],
              )),
            );
          }
        } else {
          print('No user is logged in.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Row(
                  children: [
                    Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                    Text(
                        'No user is logged in. Please log in to save the section.'),
                  ],
                )),
          );
        }
      } catch (e) {
        print('Error saving section: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
              Text('Error saving section: $e'),
            ],
          )),
        );
      }
    } else {
      // Show an error message if no section is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(
          children: [
            Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
            Text('Please select a section before saving.'),
          ],
        )),
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
            _subjects = subjectSnapshot.docs
                .where((doc) {
                  String strandCourse =
                      doc['strandcourse']; // Assuming this field exists

                  // Call the getStrandCourse method to check if the courses match
                  return strandCourse == getStrandCourse(_strand);
                })
                .map((doc) => {
                      'subject_code': doc[
                          'subject_code'], // Adjust field names if necessary
                      'subject_name': doc['subject_name'],
                      'category':
                          doc['category'], // Assuming 'category' field exists
                    })
                .toList();
          });

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Row(
              children: [
                Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                Text('Subjects loaded successfully!'),
              ],
            )),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Row(
              children: [
                Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                Text('No matching section found.'),
              ],
            )),
          );
        }
      } catch (e) {
        print('Error loading subjects: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
              Text('Error loading subjects: $e'),
            ],
          )),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Row(
              children: [
                Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                Text('Please select a section before loading subjects.'),
              ],
            )),
      );
    }
  }

  bool _isFinalized = false;

  Future<void> _fetchSubjects() async {
    try {
      // Get the user document reference using the student ID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('student_id', isEqualTo: _studentId)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userDocId = userDoc.docs.first.id;

        // Fetch subjects data from the sections subcollection for the selected section
        final sectionDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDocId)
            .collection('sections')
            .doc(_selectedSection)
            .get();

        if (sectionDoc.exists) {
          setState(() {
            _subjects = List<Map<String, dynamic>>.from(
                sectionDoc.data()?['subjects'] ?? []);
            _isFinalized = sectionDoc.data()?['isFinalized'] ?? false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
              Text('Error: User not found.'),
            ],
          )),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(
          children: [
            Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
            Text('Error fetching subjects: $e'),
          ],
        )),
      );
    }
  }

  Future<void> _finalizeSelection() async {
    if (_selectedSection != null && _subjects.isNotEmpty) {
      try {
        // Get the user document reference using the student ID
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('student_id', isEqualTo: _studentId)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          final userDocId = userDoc.docs.first.id;

            final Timestamp finalizationTime = Timestamp.now();

          // Set the data in the sections subcollection inside this user's document
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDocId)
              .collection('sections')
              .doc(userDocId)
              .set({
            'selectedSection': _selectedSection,
            'subjects': _subjects,
            'isFinalized': true,
            'finalizationTimestamp': finalizationTime, // Add timestamp
          });

          setState(() {
            _isFinalized = true; // Disable further editing
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Row(
                  children: [
                    Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                    Text('Section and subjects finalized successfully!'),
                  ],
                )),
          );

          // Fetch subjects again to update the table view with the saved data
          _fetchSubjects();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Row(
              children: [
                Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                Text('Error: User not found.'),
              ],
            )),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
              Text('Error finalizing selection: $e'),
            ],
          )),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Row(
              children: [
                Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                Text('Please select a section and load subjects first.'),
              ],
            )),
      );
    }
  }

  Future<void> _fetchSections() async {
    try {
      // Define the mapping between seniorHigh_Strand descriptive names and abbreviations
      Map<String, String> strandMap = {
        'Science, Technology, Engineering and Mathematics (STEM)': 'STEM',
        'Humanities and Social Sciences (HUMSS)': 'HUMSS',
        'Accountancy, Business, and Management (ABM)': 'ABM',
        'Information and Communication Technology (ICT)': 'ICT',
        'Home Economics (HE)': 'HE',
        'Industrial Arts (IA)': 'IA'
      };

      // Get the currently logged-in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch the user document to get seniorHigh_Strand and grade_level
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          String userStrand = userDoc['seniorHigh_Strand'];
          String userGradeLevel = userDoc['grade_level'];
          String userSemester = userDoc['semester']; // Get user's semester

          // Get the abbreviation for the user's strand
          String? strandAbbreviation = strandMap[userStrand];

          if (strandAbbreviation != null) {
            // Fetch sections that match the user's grade level and strand abbreviation
            final snapshot = await FirebaseFirestore.instance
                .collection('sections')
                .where('section_name',
                    isGreaterThanOrEqualTo:
                        '$userGradeLevel-$strandAbbreviation')
                .where('section_name',
                    isLessThanOrEqualTo:
                        '$userGradeLevel-$strandAbbreviation\uf8ff')
                .get();

            setState(() {
              _sections = snapshot.docs
                  .where((doc) =>
                      doc['semester'] == userSemester) // Add semester check
                  .map((doc) => doc['section_name'] as String)
                  .toList();
            });
            if (_sections.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Row(
                      children: [
                        Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                        Text('No sections available for your semester.'),
                      ],
                    )),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Row(
                children: [
                  Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                  Text('Strand abbreviation not found.'),
                ],
              )),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Row(
              children: [
                Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
                Text('User document not found.'),
              ],
            )),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
              Text('No user is logged in.'),
            ],
          )),
        );
      }
    } catch (e) {
      print('Error fetching sections: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(
          children: [
            Image.asset('PBMA.png', scale: 40),
                      SizedBox(width: 10),
            Text('Error fetching sections: $e'),
          ],
        )),
      );
    }
  }
  // Case 2

  Future<bool> _canSelectSection() async {
    if (_selectedSection != null) {
      // Fetch the section's document to check the capacity
      final sectionDoc = await FirebaseFirestore.instance
          .collection('sections')
          .doc(_selectedSection)
          .get();

      if (sectionDoc.exists) {
        int capacityCount = sectionDoc['capacityCount'] ?? 0;
        int capacity = sectionDoc['capacity'] ?? 0;
        return capacityCount <
            capacity; // Return true if there's available capacity
      }
    }
    return true; // Default to true if no section is selected
  }

  String getStrandCourse(String seniorHighStrand) {
    switch (seniorHighStrand) {
      case 'Accountancy, Business, and Management (ABM)':
        return 'ABM';
      case 'Information and Communication Technology (ICT)':
        return 'ICT';
      case 'Science, Technology, Engineering and Mathematics (STEM)':
        return 'STEM';
      case 'Humanities and Social Sciences (HUMSS)':
        return 'HUMSS';
      case 'Home Economics (HE)':
        return 'HE';
      case 'Industrial Arts (IA)':
        return 'IA';
      default:
        return ''; // Return an empty string or some default value if there's no match
    }
  }

  File? _imageFile; // For mobile (Android/iOS)
  Uint8List? _imageBytes; // For web

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

  final ImagePicker picker = ImagePicker();

  bool _isHovered = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, store the image as Uint8List
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFile = null; // Clear mobile file if on web
        });
      } else {
        // For mobile, store the image as File
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageBytes = null; // Clear web bytes if on mobile
        });
      }
    }
  }

  Future<void> replaceProfilePicture() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("No user is currently signed in.");
        return;
      }

      final userQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (userQuerySnapshot.docs.isEmpty) {
        print("User document not found for UID: ${currentUser.uid}");
        return;
      }

      final userDoc = userQuerySnapshot.docs.first;
      final userDocRef = userDoc.reference;

      String? oldImageUrl = userDoc.data()['image_url'];
      print("Old Image URL: $oldImageUrl");

      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        try {
          final oldImageRef = FirebaseStorage.instance.refFromURL(oldImageUrl);
          await oldImageRef.delete();
          print("Old profile picture deleted successfully.");
        } catch (e) {
          print("Failed to delete old profile picture: $e");
        }
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('student_pictures')
          .child('${DateTime.now().toIso8601String()}.png');

      if (_imageBytes != null) {
        await storageRef.putData(_imageBytes!);
      } else if (_imageFile != null) {
        await storageRef.putFile(_imageFile!);
      } else {
        print("No image selected.");
        return;
      }

      final newImageUrl = await storageRef.getDownloadURL();
      print("New Image URL: $newImageUrl");

      await userDocRef.update({'image_url': newImageUrl});
      print("Profile picture updated successfully.");

      // Update the imageNotifier with the new URL to trigger a rebuild in ExampleSidebarX
      if (mounted) {
        widget.imageNotifier.value = newImageUrl;
      }
    } catch (e) {
      print("Failed to replace profile picture: $e");
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("User logged out successfully");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (builder) => Launcher()));
    } catch (e) {
      print("Error logging out: $e");
    }
  }

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
  if (semesterGrades.isEmpty) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Color.fromARGB(255, 1, 93, 168),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset(
            'assets/PBMA.png',
            width: screenWidth / 2.5,
            height: screenHeight / 2.5,
          ),
        ),
        SizedBox(height: 10,),
            Text(
              'No grades found.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 30,
                ),
            ),
          ],
        ),
      ),
    );
  }
  return LayoutBuilder(
    builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width;

      // Adjust font sizes dynamically
      double titleFontSize = screenWidth < 600 ? 18 : 24;
      double semesterFontSize = screenWidth < 600 ? 14 : 20;
      double tableFontSize = screenWidth < 600 ? 12 : 14;
      double principalFontSize = screenWidth < 600 ? 10 : 12;
      double buttonPadding = screenWidth < 600 ? 20 : 30;

      return Container(
        width: double.infinity,
        height: double.infinity, // Fill the screen height
        color: Color.fromARGB(255, 1, 93, 168),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPORT CARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                ...semesterGrades.entries.map((entry) {
                  String semester = entry.key;
                  List<Map<String, String>> grades = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semester,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: semesterFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        child: Table(
                          border: TableBorder.all(color: Colors.black),
                          columnWidths: {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(4),
                            2: FlexColumnWidth(2),
                          },
                          children: [
                            TableRow(children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Course Code',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: tableFontSize,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Subject',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: tableFontSize,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Grade',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: tableFontSize,
                                  ),
                                ),
                              ),
                            ]),
                            ...grades.map((subject) {
                              return TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    subject['subject_code'] ?? '',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: tableFontSize,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    subject['subject_name'] ?? '',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: tableFontSize,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    subject['grade'] ?? 'N/A',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: tableFontSize,
                                    ),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }).toList(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    
                    // Principal's Section on the right
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Text(
                            'Urbano Delos Angeles IV',
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 12 : 18,
                              fontFamily: "B",
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: screenWidth < 600 ? 150 : 250,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.blue, Colors.yellow],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'SCHOOL PRINCIPAL',
                          style: TextStyle(
                            fontSize: principalFontSize,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

          case 2:
             return _isLoading 
    ? Container(
      color: Color.fromARGB(255, 1, 93, 168),
      child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  WavyAnimatedText('LOADING...'),
                ],
                isRepeatingAnimation: true,
              ),
            ),
          ),
    )
    : EnrollmentStatusWidget(
        enrollmentStatus: _enrollmentStatus,
        studentId: _studentId,
        fullName: _fullName,
        strand: _strand,
        track: _track,
        gradeLevel: _gradeLevel,
        semester: _semester,
        sections: _sections,
        subjects: _subjects,
        isFinalized: _isFinalized,
        selectedSection: _selectedSection,
        onSectionChanged: (newValue) {
          setState(() {
            _selectedSection = newValue;
          });
        },
        onLoadSubjects: _loadSubjects,
        onFinalize: _saveandfinalization,
        FinalizedData: _fetchSavedSectionData,
        checkEnrollmentStatus: _checkEnrollmentStatus, // Add this line
      );
          case 3:
            double screenWidth = MediaQuery.of(context).size.width;
            final bool isMobile = screenWidth < 600;
            final bool isTablet = screenWidth >= 600 && screenWidth < 1200;
            final bool isWeb = screenWidth >= 1200;

            
            // Define width for text fields based on screen size
            double fieldWidth;
            if (screenWidth >= 1200) {
              // Large screens (Web/Desktop)
              fieldWidth = 270;
            } else if (screenWidth >= 800) {
              // Medium screens (Tablet)
              fieldWidth = 240;
            } else {
              // Small screens (Mobile)
              fieldWidth = screenWidth * 0.8; // Adjust to take most of the screen width
            }

            // Define spacing between fields
            double spacing = screenWidth >= 800 ? 16.0 : 8.0;

            // long term words
            final double textFontSize1 = isMobile ? 10 : (isTablet ? 8 : 9);
            final double textFontSize2 = isMobile ? 8 : (isTablet ? 6 : 7);
            final double textFontSize3 = isMobile ? 12 : (isTablet ? 10 : 11);
            final double textFontSize4 = isMobile ? 10 : (isTablet ? 8 : 9);
            
            if (_isLoading) {
              return Container(
                color: const Color.fromARGB(255, 1, 93, 168),
                child: Center(
                          child: DefaultTextStyle(
                            style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                            ),
                            child: AnimatedTextKit(
                animatedTexts: [
                  WavyAnimatedText('LOADING...'),
                ],
                isRepeatingAnimation: true,
                            ),
                          ),
                        ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
              // Get screen width
              double butWidth = constraints.maxWidth;
              final bool isMobiles = butWidth < 600;
              final bool isTablets = butWidth >= 600 && butWidth < 1200;
              final bool isWebs = butWidth >= 1200;
              

              return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Container(
                      color: Color.fromARGB(255, 1, 93, 168),
                      width: screenWidth,
                      child: Container(
                        margin: EdgeInsets.all(isMobiles ? 15 : 30),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          await _pickImage(); // Open image picker to select a new image
              
                                          if (_imageBytes != null ||
                                              _imageFile != null) {
                                            await replaceProfilePicture(); // Upload and replace the profile picture
              
                                            // Reload the new image URL from Firestore after uploading
                                            await _imageGetterFromExampleState();
              
                                            setState(
                                                () {}); // Refresh the UI after updating the image URL
                                          }
                                        },
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
                                                radius: isMobiles ? 50 : 85,
                                                backgroundImage: _imageBytes !=
                                                        null
                                                    ? MemoryImage(_imageBytes!)
                                                        as ImageProvider
                                                    : _imageFile != null
                                                        ? FileImage(_imageFile!)
                                                            as ImageProvider
                                                        : _imageUrl != null
                                                            ? NetworkImage(
                                                                    _imageUrl!)
                                                                as ImageProvider
                                                            : const NetworkImage(
                                                                'https://cdn4.iconfinder.com/data/icons/linecon/512/photo-512.png',
                                                              ),
                                              ),
                                              if (_isHovered)
                                                Container(
                                                  width: isMobiles ? 100 : 170,
                                                  height: isMobiles ? 100 : 170,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.white,
                                                    size: 60,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ).showCursorOnHover,
                                      SizedBox(width: isMobiles ? 10 : 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            children: [
                                              Text(
                                                  "${userData['first_name'] ?? 'N/A'}",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "B",
                                                      fontSize: isMobiles ? 14 : 25),
                                                ),
                                              
                                              SizedBox(
                                                width: 7,
                                              ),
                                              Text(
                                                  "${userData['middle_name'] ?? 'N/A'}",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "B",
                                                      fontSize: isMobiles ? 14 : 25),
                                                ),
                                              
                                              SizedBox(
                                                width: 7,
                                              ),
                                              Text(
                                                  "${userData['last_name'] ?? 'N/A'}",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "B",
                                                      fontSize: isMobiles ? 14 : 25),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 15),
                                          Wrap(
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  await _pickImage(); // Open image picker to select a new image
              
                                                  if (_imageBytes != null ||
                                                      _imageFile != null) {
                                                    await replaceProfilePicture(); // Upload and replace the profile picture
              
                                                    // Reload the new image URL from Firestore after uploading
                                                    await _imageGetterFromExampleState();
              
                                                    setState(
                                                        () {}); // Refresh the UI after updating the image URL
                                                  }
                                                },
                                                child: Container(
                                                  height: isMobiles ? 30 : 40,
                                                  width: isMobiles ? 100 : 150,
                                                  decoration: BoxDecoration(
                                                    color: Colors.yellow,
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        "Edit Profile",
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontFamily: "B",
                                                            fontSize: isMobiles ? 12 : 15,),
                                                      ),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Icon(
                                                        Icons.edit,
                                                        size: isMobiles ? 12 : 15,
                                                        color: Colors.black,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ).showCursorOnHover.moveUpOnHover,
                                              SizedBox(
                                                width: 15,
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  logout();
                                                },
                                                child: Container(
                                                  height: isMobiles ? 30 : 40,
                                                  width: isMobiles ? 100 : 150,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        "Logout",
                                                        style: TextStyle(
                                                            color: Color.fromARGB(
                                                                255, 1, 93, 168),
                                                            fontFamily: "B",
                                                            fontSize: isMobiles ? 12 : 15),
                                                      ),
                                                      SizedBox(
                                                        width: 3,
                                                      ),
                                                      Icon(
                                                        Icons.logout_rounded,
                                                        size: isMobiles ? 15 : 20,
                                                        color: Color.fromARGB(
                                                            255, 1, 93, 168),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ).showCursorOnHover.moveUpOnHover,
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 40,
                              ),
                              Text(
                                "Student Information",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 25,
                                    fontFamily: "SB"),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Wrap(
                              spacing: spacing,
                                          runSpacing: spacing,                              
                                  children: [
                                  Column(
                                    children: [
                                      Text(
                                        "First Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['first_name'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Middle Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['middle_name'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Last Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['last_name'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Extension Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['extension_name'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                  Column(
                                    children: [
                                      Text(
                                        "Age",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['age'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Gender",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['gender'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Birthdate",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['birthdate'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Email Address",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['email_Address'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: (userData['email_Address']?.length ?? 0) > 45 ? textFontSize4 : textFontSize3,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                        children: [
                                          // if (phoneController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "Phone Number",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                          
                                        
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: phoneController,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '09********',
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your phone number';
                                            }
                                            // Ensure the number starts with '09' and has exactly 11 digits
                                            if (!RegExp(r'^(09\d{9})$')
                                                .hasMatch(value)) {
                                              return 'Enter a valid phone number starting with 09 (e.g., 09xxxxxxxxx)';
                                            }
                                            return null;
                                          },
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(11),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Indigenous People (IP)",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['indigenous_group'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Student Number",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['student_id'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "LRN",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['lrn'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                "Home Address",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 25,
                                    fontFamily: "SB"),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  Column(
                                        children: [
                                          // if (houseNumberController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "House Number",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: houseNumberController,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          inputFormatters: [
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              // Capitalize the first letter of every word after a space
                                              String newText = newValue.text
                                                  .split(' ')
                                                  .map((word) {
                                                if (word.isNotEmpty) {
                                                  return word[0].toUpperCase() +
                                                      word
                                                          .substring(1)
                                                          .toLowerCase();
                                                }
                                                return ''; // Handle empty words
                                              }).join(' '); // Join back the words with spaces
                                              return newValue.copyWith(
                                                  text: newText,
                                                  selection: newValue.selection);
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                          // if (streetNameController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "Street Name",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: streetNameController,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your street name';
                                            }
                                            return null;
                                          },
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          inputFormatters: [
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              // Capitalize the first letter of every word after a space
                                              String newText = newValue.text
                                                  .split(' ')
                                                  .map((word) {
                                                if (word.isNotEmpty) {
                                                  return word[0].toUpperCase() +
                                                      word
                                                          .substring(1)
                                                          .toLowerCase();
                                                }
                                                return ''; // Handle empty words
                                              }).join(' '); // Join back the words with spaces
                                              return newValue.copyWith(
                                                  text: newText,
                                                  selection: newValue.selection);
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                          // if (subdivisionBarangayController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "Subdivision/Barangay",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller:
                                              subdivisionBarangayController,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your barangay';
                                            }
                                            return null;
                                          },
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          inputFormatters: [
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              // Capitalize the first letter of every word after a space
                                              String newText = newValue.text
                                                  .split(' ')
                                                  .map((word) {
                                                if (word.isNotEmpty) {
                                                  return word[0].toUpperCase() +
                                                      word
                                                          .substring(1)
                                                          .toLowerCase();
                                                }
                                                return ''; // Handle empty words
                                              }).join(' '); // Join back the words with spaces
                                              return newValue.copyWith(
                                                  text: newText,
                                                  selection: newValue.selection);
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                          // if (cityMunicipalityController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "City/Municipality",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: cityMunicipalityController,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your municipality';
                                            }
                                            return null;
                                          },
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          keyboardType: TextInputType.text,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[a-zA-z\s]')),
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              // Capitalize the first letter of every word after a space
                                              String newText = newValue.text
                                                  .split(' ')
                                                  .map((word) {
                                                if (word.isNotEmpty) {
                                                  return word[0].toUpperCase() +
                                                      word
                                                          .substring(1)
                                                          .toLowerCase();
                                                }
                                                return ''; // Handle empty words
                                              }).join(' '); // Join back the words with spaces
                                              return newValue.copyWith(
                                                  text: newText);
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                          // if (provinceController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "Province",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          textCapitalization:
                                              TextCapitalization.words,
                                          controller: provinceController,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your province';
                                            }
                                            return null;
                                          },
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          keyboardType: TextInputType.text,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[a-zA-z\s]')),
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              // Capitalize the first letter of every word after a space
                                              String newText = newValue.text
                                                  .split(' ')
                                                  .map((word) {
                                                if (word.isNotEmpty) {
                                                  return word[0].toUpperCase() +
                                                      word
                                                          .substring(1)
                                                          .toLowerCase();
                                                }
                                                return ''; // Handle empty words
                                              }).join(' '); // Join back the words with spaces
                                              return newValue.copyWith(
                                                  text: newText);
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                          // if (countryController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "Country",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: countryController,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your country';
                                            }
                                            return null;
                                          },
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          keyboardType: TextInputType.text,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[a-zA-z\s]')),
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              // Capitalize the first letter of every word after a space
                                              String newText = newValue.text
                                                  .split(' ')
                                                  .map((word) {
                                                if (word.isNotEmpty) {
                                                  return word[0].toUpperCase() +
                                                      word
                                                          .substring(1)
                                                          .toLowerCase();
                                                }
                                                return ''; // Handle empty words
                                              }).join(' '); // Join back the words with spaces
                                              return newValue.copyWith(
                                                  text: newText);
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                "Parent Guardian Information",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 25,
                                    fontFamily: "SB"),
                              ),
                              Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "Father's Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['fathersName'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Mother's Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['mothersName'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Guardian's Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['guardianName'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Relationship",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['relationshipGuardian'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                          // if (cellphoneNumController.text.isNotEmpty)
                                          RichText(
                                            text: TextSpan(
                                              text: "Phone Number",
                                              style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            children: [
                                              TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,                            ),
                                              ),
                                            ]
                                            )
                                            
                                          ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: cellphoneNumController,
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '09********',
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your phone number';
                                            }
                                            // Ensure the number starts with '09' and has exactly 11 digits
                                            if (!RegExp(r'^(09\d{9})$')
                                                .hasMatch(value)) {
                                              return 'Enter a valid phone number starting with 09 (e.g., 09xxxxxxxxx)';
                                            }
                                            return null;
                                          },
                                          onChanged: (text) {
                                            setState(() {});
                                          },
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(11),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                "Senior High School(SHS)",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 25,
                                    fontFamily: "SB"),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "Grade Level",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['grade_level'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Transferee",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['transferee'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Track",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['seniorHigh_Track'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Strand",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['seniorHigh_Strand'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: (userData['seniorHigh_Strand']?.length ?? 0) > 45 ? textFontSize2 : textFontSize1,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Semester",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['semester'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                "Junior High School(JHS)",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 25,
                                    fontFamily: "SB"),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "JHS Name",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['juniorHS'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: (userData['juniorHS']?.length ?? 0) > 45 ? textFontSize2 : textFontSize1,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "School Address",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          initialValue:
                                              "${userData['schoolAdd'] ?? 'N/A'}",
                                          enabled: false,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontFamily: "R",
                                            fontSize: (userData['schoolAdd']?.length ?? 0) > 45 ? textFontSize2 : textFontSize1,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(left: 10),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                "Change Password",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 25,
                                    fontFamily: "SB"),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "New Password",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: _newPasswordController,
                                          obscureText: _obscureTextNew,
                                          validator: (value) {
                                            if (value != null &&
                                                value.isNotEmpty &&
                                                value !=
                                                    _confirmPasswordController
                                                        .text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter new password',
                                            contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0), 
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            prefixIcon: Icon(Icons.lock_outline),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureTextNew
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureTextNew =
                                                      !_obscureTextNew;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Confirm Password",
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      Container(
                                        width: fieldWidth,
                                        child: TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureTextConfirm,
                                          validator: (value) {
                                            if (value != null &&
                                                value.isNotEmpty &&
                                                value !=
                                                    _newPasswordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                          enabled: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "R",
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Confirm New Password',
                                            contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0), 
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide:
                                                  BorderSide(color: Colors.white),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            prefixIcon: Icon(Icons.lock_outline),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureTextConfirm
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureTextConfirm =
                                                      !_obscureTextConfirm;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              if (_passwordMismatch)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                        'Passwords do not match',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: Container(
                                        height: isMobiles ? 30 : 40,
                                        width: isMobiles ? 100 : 150,
                                        child: ElevatedButton(
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Colors.yellow),
                                              elevation: MaterialStateProperty
                                                  .all<double>(5),
                                              shape: MaterialStateProperty.all<
                                                  OutlinedBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            onPressed: _updateUserData,
                                            child: Text(
                                              'Save',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: isMobiles ? 14 : 18,),
                                            ))),
                                  )
                            ]),
                      ),
                    ),
                  )
              );
        });
        
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
