import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pbma_portal/Manage/AddingSections.dart';
import 'package:pbma_portal/Manage/AddingSubjects.dart';
import 'package:pbma_portal/Manage/EditInstructor.dart';
import 'package:pbma_portal/Manage/EditSections.dart';
import 'package:pbma_portal/Manage/EditSubject.dart';
import 'package:pbma_portal/Manage/SubjectsandGrade.dart';
import 'package:pbma_portal/launcher.dart';
import 'package:pbma_portal/pages/Auth_View/Adding_InstructorAcc_Desktview.dart';
import 'package:pbma_portal/pages/student_details.dart';
import 'package:pbma_portal/student_utils/Student_Utils.dart';
import 'package:pbma_portal/Admin Dashboard Sorting/Dashboard Sorting.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, bool> _selectedStudents = {};
  String _selectedDrawerItem = 'Dashboard';
  String _email = '';
  String _accountType = '';
  int _gradeLevelIconState = 0;
  int _transfereeIconState = 0;
  int _trackIconState = 0;
  String _selectedStrand = 'ALL';
  
  String? selectedSubjectId;
  String? selectedInstructorId;
  String? selectedSectionId;

  bool _showAddSubjects = false;
  bool _showEditSubjects = false;
  bool _showAddInstructors = false;
  bool _showEditInstructors = false;
  bool _showAddSections = false;
  bool _showEditSections = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Map<String, String> strandMapping = {
    'STEM': 'Science, Technology, Engineering and Mathematics (STEM)',
    'HUMSS': 'Humanities and Social Sciences (HUMSS)',
    'ABM': 'Accountancy, Business, and Management (ABM)',
    'ICT': 'Information and Communication Technology (ICT)',
    'HE': 'Home Economics (HE)',
    'IA': 'Industrial Arts (IA)',
  };

  //BuildDashboardContent
  Stream<QuerySnapshot> _getEnrolledStudentsCount() {
    Query query = FirebaseFirestore.instance.collection('users')
    .where('Status', isEqualTo: 'active')
    .where('enrollment_status',isEqualTo: 'approved'); // Always filter by 'approved'

    // Map icon states to Firestore values
    String? trackValue;
    if (_trackIconState == 1) {
      trackValue = 'Academic Track'; // Replace with actual Firestore value
    } else if (_trackIconState == 2) {
      trackValue =
          'Technical-Vocational-Livelihood (TVL)'; // Replace with actual Firestore value
    }
    if (trackValue != null) {
      query = query.where('seniorHigh_Track', isEqualTo: trackValue);
    }

    // Map grade level states
    String? gradeLevelValue;
    if (_gradeLevelIconState == 1) {
      gradeLevelValue = '11'; // Replace with actual Firestore value
    } else if (_gradeLevelIconState == 2) {
      gradeLevelValue = '12'; // Replace with actual Firestore value
    }
    if (gradeLevelValue != null) {
      query = query.where('grade_level', isEqualTo: gradeLevelValue);
    }

    // Map transferee states
    String? transfereeValue;
    if (_transfereeIconState == 1) {
      transfereeValue = 'yes'; // Replace with actual Firestore value
    } else if (_transfereeIconState == 2) {
      transfereeValue = 'no'; // Replace with actual Firestore value
    }
    if (transfereeValue != null) {
      query = query.where('transferee', isEqualTo: transfereeValue);
    }

    // Add strand filter only if it's not 'ALL'
    if (_selectedStrand != 'ALL') {
      String? strandValue = strandMapping[_selectedStrand];

      if (strandValue != null) {
        print("Applying strand filter: $strandValue");
        query = query.where('seniorHigh_Strand', isEqualTo: strandValue);
      }
    }

    return query.snapshots();
  }
  //BuildDashBoardContent


  //BuildStudentsContent
  void moveToDropList() async {
    List<String> selectedStudentIds = _selectedStudents.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (selectedStudentIds.isNotEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String studentId in selectedStudentIds) {
        // Query the collection to find the document with student_id == studentId
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('student_id', isEqualTo: studentId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Assuming 'student_id' is unique and we only get one document
          DocumentReference studentDoc = querySnapshot.docs.first.reference;

          // Add the 'Status' field and set its value to 'drop'
          batch.update(studentDoc, {'Status': 'inactive'});
        } else {
          // Handle the case where the document doesn't exist
          print('Document with student_id $studentId not found.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Student with ID $studentId not found')),
          );
        }
      }

      // Commit the batch update if there are valid documents to update
      await batch.commit();

      // Optional: Show a confirmation message if some updates were successful
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected students moved to drop list')));

      // Clear the selected students list after updating Firestore
      setState(() {
        _selectedStudents.clear();
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No students selected')));
    }
  }

  Stream<QuerySnapshot> _getFilteredStudents() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('accountType', isEqualTo: 'student')
        .where('Status', isEqualTo: 'active'); // Filter for active students

    if (_trackIconState == 1) {
      query = query.where('seniorHigh_Track', isEqualTo: 'Academic Track');
    } else if (_trackIconState == 2) {
      query = query.where('seniorHigh_Track',
          isEqualTo: 'Technical-Vocational-Livelihood (TVL)');
    }

    // Add additional filters for grade level
    if (_gradeLevelIconState == 1) {
      query = query.where('grade_level', isEqualTo: '11');
    } else if (_gradeLevelIconState == 2) {
      query = query.where('grade_level', isEqualTo: '12');
    }

    // Add additional filters for transferee status
    if (_transfereeIconState == 1) {
      query = query.where('transferee', isEqualTo: 'yes');
    } else if (_transfereeIconState == 2) {
      query = query.where('transferee', isEqualTo: 'no');
    }

    // Add additional filters for selected strand
    if (_selectedStrand != 'ALL') {
      String? strandValue = strandMapping[_selectedStrand];

      if (strandValue != null) {
        print("Applying strand filter: $strandValue");
        query = query.where('seniorHigh_Strand', isEqualTo: strandValue);
      }
    }
    // Return the query snapshots
    return query.snapshots();
  }

  bool get _isAnyStudentSelected {
    return _selectedStudents.values.any((isSelected) => isSelected);
  }

  void _showConfirmationStudentDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text("Confirm Action"),
        content: Text("Are you sure you want to move the selected students to the drop list?"),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          CupertinoDialogAction(
            child: Text("Yes"),
            onPressed: () {
              moveToDropList(); // Call your function to move to drop list
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}
  //BuildStudentsContent


  //BuildStrandInstructorContent
  Stream<QuerySnapshot<Map<String, dynamic>>>_getFilteredInstructorStudents() async* {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    final userData = userDoc.data()!;
    final userGradeLevel = userData['gradeLevel'];
    final userStrand = userData['strand'];
    final userTrack = userData['track'];

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('grade_level', isEqualTo: userGradeLevel)
        .where('seniorHigh_Strand', isEqualTo: userStrand)
        .where('seniorHigh_Track', isEqualTo: userTrack)
        .where('enrollment_status', isEqualTo: 'approved')
        .where('accountType', isEqualTo: 'student');

    if (_trackIconState != 0) {
      query = query.where('seniorHigh_Track', isEqualTo: _trackIconState);
    }

    if (_gradeLevelIconState != 0) {
      query = query.where('grade_level', isEqualTo: _gradeLevelIconState);
    }

    if (_selectedStrand != 'ALL') {
      query = query.where('seniorHigh_Strand', isEqualTo: _selectedStrand);
    }

    yield* query.snapshots();
  }
  //BuildStrandInstructorContent


   //BuildNewcomersContent
  Stream<QuerySnapshot> _getNewcomersStudents() {
    return getNewcomersStudents(_trackIconState, _gradeLevelIconState,
        _transfereeIconState, _selectedStrand);
  }

  void deleteNewComersStudent(String studentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete student: $e')),
      );
    }
  }
   //BuildNewcomersContent


  //BuildManageSubjectsContent
  void toggleAddSubjects() {
    setState(() {
      _showAddSubjects = !_showAddSubjects;
    });
  }

  void closeAddSubjects() {
    setState(() {
      _showAddSubjects = false;
    });
  }

  void toggleEditSubjects() {
    setState(() {
      _showEditSubjects = !_showEditSubjects;
    });
  }

  void closeEditSubjects() {
    setState(() {
      _showEditSubjects = false;
    });
  }

  void _deleteSubject(String subjectId) async {
    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting subject: $e')),
      );
    }
  }

  void _showDeleteSubjectConfirmation(BuildContext context, String subjectId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this subject?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          CupertinoDialogAction(
            child: Text('Yes'),
            onPressed: () {
              _deleteSubject(subjectId); // Call delete function
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      ),
    );
  }
  //BuildManageSubjectsContent


  //BuildManageInstructorContent
 void toggleAddInstructors() {
    setState(() {
      _showAddInstructors = !_showAddInstructors;
    });
  }

  void closeAddInstructors() {
    setState(() {
      _showAddInstructors = false;
    });
  }

  void toggleEditInstructors() {
    setState(() {
      _showEditInstructors = !_showEditInstructors;
    });
  }

  void closeEditInstructors() {
    setState(() {
      _showEditInstructors = false;
    });
  }

  Future<void> _setInstructorStatusInactive(String instructorId) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(instructorId).update({
      'Status': 'inactive', // Change the field name if it's different
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Instructor status updated to inactive')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update status: $e')),
    );
  }
}

Future<void> _setInstructorStatusActive(String instructorId) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(instructorId).update({
      'Status': 'active', // Change the field name if it's different
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Instructor status updated to inactive')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update status: $e')),
    );
  }
}

  void _showStatusChangeDialog(BuildContext context, String instructorId, String newStatus) {
  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text("Confirm Action"),
        content: Text("Are you sure you want to change the status to $newStatus?"),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          CupertinoDialogAction(
            child: Text("Yes"),
            onPressed: () {
              // Call the appropriate method based on the new status
              if (newStatus == 'inactive') {
                _setInstructorStatusInactive(instructorId); // Call the method
              } else {
                _setInstructorStatusActive(instructorId); // Call the method
              }
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}
  //BuildManageInstructorContent


  //BuildDropStudent
  Stream<QuerySnapshot> _getFilteredDropStudents() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('accountType', isEqualTo: 'student')
        .where('Status', isEqualTo: 'inactive'); // Filter for active students

    if (_trackIconState == 1) {
      query = query.where('seniorHigh_Track', isEqualTo: 'Academic Track');
    } else if (_trackIconState == 2) {
      query = query.where('seniorHigh_Track',
          isEqualTo: 'Technical-Vocational-Livelihood (TVL)');
    }

    // Add additional filters for grade level
    if (_gradeLevelIconState == 1) {
      query = query.where('grade_level', isEqualTo: '11');
    } else if (_gradeLevelIconState == 2) {
      query = query.where('grade_level', isEqualTo: '12');
    }

    // Add additional filters for transferee status
    if (_transfereeIconState == 1) {
      query = query.where('transferee', isEqualTo: 'yes');
    } else if (_transfereeIconState == 2) {
      query = query.where('transferee', isEqualTo: 'no');
    }

    // Add additional filters for selected strand
    if (_selectedStrand != 'ALL') {
      String? strandValue = strandMapping[_selectedStrand];

      if (strandValue != null) {
        print("Applying strand filter: $strandValue");
        query = query.where('seniorHigh_Strand', isEqualTo: strandValue);
      }
    }
    // Return the query snapshots
    return query.snapshots();
  }

 Future<void> _setStudentStatusActive(String studentId) async {
  try {
    // Retrieve the document with the matching student_id
    var studentDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('student_id', isEqualTo: studentId)
        .get();

    // Check if a document was found
    if (studentDoc.docs.isNotEmpty) {
      // Update the status field to 'active'
      await studentDoc.docs.first.reference.update({'Status': 'active'});
      print('Student status updated to active for ID: $studentId');
    } else {
      print('No student found with ID: $studentId');
    }
  } catch (e) {
    print('Error updating student status: $e');
  }
}

  void showConfirmationDropDialog(BuildContext context, String studentId) async {
  return showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text('Confirm Action'),
        content: Text('Do you want to activate this student?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          CupertinoDialogAction(
            child: Text('Yes'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog after action
              _setStudentStatusActive(studentId); // Call the function to set student status active
            },
          ),
        ],
      );
    },
  );
}
  //BuildDropStudent


  //BuildManageSections
  void toggleAddSections() {
    setState(() {
      _showAddSections = !_showAddSections;
    });
  }

  void closeAddSections() {
    setState(() {
      _showAddSections = false;
    });
  }

  void toggleEditSections() {
    setState(() {
      _showEditSections = !_showEditSections;
    });
  }

  void closeEditSections() {
    setState(() {
      _showEditSections = false;
    });
  }

  void _deleteSection(String sectionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('sections')
          .doc(sectionId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Section deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting section: $e')),
      );
    }
  }

  void _showDeleteSectionConfirmation(BuildContext context, String sectionId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this subject?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          CupertinoDialogAction(
            child: Text('Yes'),
            onPressed: () {
              _deleteSection(sectionId); // Call delete function
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      ),
    );
  }
  //BuildManageSections


  //Filtering
  void _toggleGradeLevelIcon() {
    setState(() {
      _gradeLevelIconState =
          (_gradeLevelIconState + 1) % 3; // Cycles through 0, 1, 2
    });
  }

  void _toggleTransfereeIcon() {
    setState(() {
      _transfereeIconState =
          (_transfereeIconState + 1) % 3; // Cycles through 0, 1, 2
    });
  }

  void _toggleTrackIcon() {
    setState(() {
      _trackIconState = (_trackIconState + 1) % 3; // Cycles through 0, 1, 2
    });
  }
  //Filtering


   //Disabling Drawer
  bool _isItemDisabled(String item) {
    if (_accountType == 'ADMIN') {
      return item == 'Strand Instructor';
    } else if (_accountType == 'INSTRUCTOR') {
      return item != 'Strand Instructor';
    }
    return false;
  }

  Widget _buildDrawerItem(String title, IconData icon, String drawerItem) {
    bool isDisabled = _isItemDisabled(drawerItem);
    return ListTile(
      leading: Icon(icon, color: isDisabled ? Colors.grey : Colors.black),
      title: Text(title,
          style: TextStyle(color: isDisabled ? Colors.grey : Colors.black)),
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedDrawerItem = drawerItem;
              });
              Navigator.of(context).pop();
            },
    );
  }
  //Disabling Drawer


  //Retrieving the Current AccountType
  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _accountType = (data['accountType'] as String).toUpperCase();
            _email = data['email_Address'];
            _selectedDrawerItem = _accountType == 'INSTRUCTOR'
                ? 'Strand Instructor'
                : 'Dashboard';
          });
        } else {
          print('No document found for UID: $uid');
          setState(() {
            _accountType = 'Not Found';
          });
        }
      } else {
        print('No current user found.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _accountType = 'Error';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBodyContent() {
    switch (_selectedDrawerItem) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'Students':
        return _buildStudentsContent();
      case 'Strand Instructor':
        return _buildStrandInstructoraContent();
      case 'Manage Newcomers':
        return _buildNewcomersContent();
      case 'Manage Subjects':
        return _buildManageSubjects();
      case 'Manage Instructors':
        return _buildManageInstructorContent();
      case 'Manage Sections':
        return _buildManageSections();
      case 'Dropped Student':
        return _buildDropStudent();
      case 'Report Analytics':
        return _buildAnalytics();
      default:
        return Center(child: Text('Body Content Here'));
    }
  }

  //method para sa Adviser and Not Adviser
  Widget _buildStrandInstructoraContent() {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('users')
        .where('accountType', isEqualTo: 'instructor')
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('No instructors found.'));
      }

      // Assuming you have a method to get the currently signed-in instructor's UID
      String currentInstructorUid = FirebaseAuth.instance.currentUser!.uid;

      // Get the document for the currently signed-in instructor
      DocumentSnapshot currentInstructorDoc = snapshot.data!.docs.firstWhere(
        (doc) => doc.id == currentInstructorUid,
        orElse: () => throw Exception('Instructor not found'),
      );

      final adviserStatus = currentInstructorDoc.get('adviser'); // Get adviser status

      // Navigate to the corresponding drawer based on adviser status
      if (adviserStatus == 'yes') {
        return _buildInstructorWithAdviserDrawer(currentInstructorDoc);
      } else {
        return _buildInstructorWithoutAdviserDrawer(currentInstructorDoc);
      }
    },
  );
}
  
  Widget _buildDashboardContent() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // "Students List" Text
                Text(
                  'Students List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 50),

                // Enrolled Students Card using StreamBuilder to fetch the count dynamically
                StreamBuilder<QuerySnapshot>(
                  stream: _getEnrolledStudentsCount(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 120,
                        height: 60,
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                            child:
                                CircularProgressIndicator()), // Loader while waiting
                      );
                    }

                    if (!snapshot.hasData) {
                      // If there are no enrolled students, display "0"
                      return Container(
                        width: 120,
                        height: 60,
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24.0,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    '0', // Display 0 if no data
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    'ENROLLED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.0,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    'STUDENTS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.0,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    int enrolledStudentsCount = snapshot.data!.docs.length;

                    return Container(
                      width: 120, // Set fixed width
                      height: 60, // Set fixed height
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0), // Adjust padding
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceEvenly, // Align the content horizontally
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24.0, // Adjust icon size to fit
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  '$enrolledStudentsCount', // Display the actual count
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'ENROLLED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        10.0, // Smaller text to fit within the box
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'STUDENTS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.0, // Smaller text to fit
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getEnrolledStudentsCount(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Checkbox(value: false, onChanged: (bool? value) {}),
                            Expanded(child: Text('Student ID')),
                            Expanded(child: Text('First Name')),
                            Expanded(child: Text('Last Name')),
                            Expanded(child: Text('Middle Name')),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Track'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTrackIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Strand'),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.arrow_drop_down),
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedStrand = value;
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        'ALL',
                                        'STEM',
                                        'HUMSS',
                                        'ABM',
                                        'ICT',
                                        'HE',
                                        'IA'
                                      ].map((String strand) {
                                        return PopupMenuItem<String>(
                                          value: strand,
                                          child: Text(strand),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Grade Level'),
                                  GestureDetector(
                                    onTap:
                                        _toggleGradeLevelIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Transferee'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTransfereeIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_transfereeIconState == 0 ||
                                            _transfereeIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_transfereeIconState == 0 ||
                                            _transfereeIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        ...students.map((student) {
                          final data = student.data() as Map<String, dynamic>;
                          return Row(
                            children: [
                              // Checkbox(
                              //     value: false, onChanged: (bool? value) {}),
                              Expanded(child: Text(data['student_id'] ?? '')),
                              Expanded(child: Text(data['first_name'] ?? '')),
                              Expanded(child: Text(data['last_name'] ?? '')),
                              Expanded(child: Text(data['middle_name'] ?? '')),
                              Expanded(
                                  child: Text(data['seniorHigh_Track'] ?? '')),
                              Expanded(
                                  child: Text(data['seniorHigh_Strand'] ?? '')),
                              Expanded(child: Text(data['grade_level'] ?? '')),
                              Expanded(child: Text(data['transferee'] ?? '')),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsContent() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Students',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // Row with Drop button (on the left) and Search Student (fixed on the right)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_isAnyStudentSelected)
                  OutlinedButton(
                    onPressed: (){
                      _showConfirmationStudentDialog(context);
                    },
                    child: Text('Move to Drop List',
                        style: TextStyle(color: Colors.black)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                // Add Spacer or Expanded to ensure Search stays on the right
                Spacer(),
                // Search Student field stays on the right
                Container(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Student',
                      prefixIcon: Icon(Iconsax.search_normal_1_copy),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs.where((student) {
                    final data = student.data() as Map<String, dynamic>;
                    final query = _searchQuery.toLowerCase();

                    final studentId = data['student_id']?.toLowerCase() ?? '';
                    final firstName = data['first_name']?.toLowerCase() ?? '';
                    final lastName = data['last_name']?.toLowerCase() ?? '';
                    final middleName = data['middle_name']?.toLowerCase() ?? '';
                    final track = data['seniorHigh_Track']?.toLowerCase() ?? '';
                    final strand =
                        data['seniorHigh_Strand']?.toLowerCase() ?? '';
                    final gradeLevel = data['grade_level']?.toLowerCase() ?? '';
                    final Transferee = data['transferee']?.toLowerCase() ?? '';

                    final fullName = '$firstName $middleName $lastName';

                    return studentId.contains(query) ||
                        fullName.contains(query) ||
                        track.contains(query) ||
                        strand.contains(query) ||
                        gradeLevel.contains(query) ||
                        Transferee.contains(query);
                  }).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                                width:
                                    32), // Same width as a checkbox to preserve alignment
                            Expanded(child: Text('Student ID')),
                            Expanded(child: Text('First Name')),
                            Expanded(child: Text('Last Name')),
                            Expanded(child: Text('Middle Name')),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Track'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTrackIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Strand'),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.arrow_drop_down),
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedStrand = value;
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        'ALL',
                                        'STEM',
                                        'HUMSS',
                                        'ABM',
                                        'ICT',
                                        'HE',
                                        'IA'
                                      ].map((String strand) {
                                        return PopupMenuItem<String>(
                                          value: strand,
                                          child: Text(strand),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Grade Level'),
                                  GestureDetector(
                                    onTap:
                                        _toggleGradeLevelIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Transferee'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTransfereeIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_transfereeIconState == 0 ||
                                            _transfereeIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_transfereeIconState == 0 ||
                                            _transfereeIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        ...students.map((student) {
                          final data = student.data() as Map<String, dynamic>;
                          String studentId = data['student_id'] ?? '';
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StudentDetails(studentData: data),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _selectedStudents[studentId] ?? false,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _selectedStudents[studentId] = value!;
                                    });
                                  },
                                ),
                                Expanded(child: Text(data['student_id'] ?? '')),
                                Expanded(child: Text(data['first_name'] ?? '')),
                                Expanded(child: Text(data['last_name'] ?? '')),
                                Expanded(
                                    child: Text(data['middle_name'] ?? '')),
                                Expanded(
                                    child:
                                        Text(data['seniorHigh_Track'] ?? '')),
                                Expanded(
                                    child:
                                        Text(data['seniorHigh_Strand'] ?? '')),
                                Expanded(
                                    child: Text(data['grade_level'] ?? '')),
                                Expanded(child: Text(data['transferee'] ?? '')),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorWithAdviserDrawer(DocumentSnapshot doc) {
    return Container(
      color: Colors.grey[300],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Strand Instructor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 300,
                  child: Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Student',
                        prefixIcon: Icon(Iconsax.search_normal_1_copy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getFilteredInstructorStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs.where((student) {
                    final data = student.data() as Map<String, dynamic>;
                    final query = _searchQuery.toLowerCase();

                    final studentId = data['student_id']?.toLowerCase() ?? '';
                    final firstName = data['first_name']?.toLowerCase() ?? '';
                    final lastName = data['last_name']?.toLowerCase() ?? '';
                    final middleName = data['middle_name']?.toLowerCase() ?? '';
                    final track = data['seniorHigh_Track']?.toLowerCase() ?? '';
                    final strand =
                        data['seniorHigh_Strand']?.toLowerCase() ?? '';

                    final fullName = '$firstName $middleName $lastName';

                    return studentId.contains(query) ||
                        fullName.contains(query) ||
                        track.contains(query) ||
                        strand.contains(query);
                  }).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(value: false, onChanged: (bool? value) {}),
                            Expanded(child: Text('Student ID')),
                            Expanded(child: Text('Name')),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Track'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTrackIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Strand'),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.arrow_drop_down),
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedStrand = value;
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        'ALL',
                                        'STEM',
                                        'HUMSS',
                                        'ABM',
                                        'ICT',
                                        'HE',
                                        'IA'
                                      ].map((String strand) {
                                        return PopupMenuItem<String>(
                                          value: strand,
                                          child: Text(strand),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Grade Level'),
                                  GestureDetector(
                                    onTap:
                                        _toggleGradeLevelIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: Text('Average')),
                          ],
                        ),
                        Divider(),
                        ...students.map((student) {
                          final data = student.data();
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SubjectsandGrade(
                                            studentData: data,
                                          )));
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                    value: false, onChanged: (bool? value) {}),
                                Expanded(child: Text(data['student_id'] ?? '')),
                                Expanded(
                                    child: Text(
                                        '${data['first_name'] ?? ''} ${data['middle_name'] ?? ''} ${data['last_name'] ?? ''}')),
                                Expanded(
                                    child:
                                        Text(data['seniorHigh_Track'] ?? '')),
                                Expanded(
                                    child:
                                        Text(data['seniorHigh_Strand'] ?? '')),
                                Expanded(
                                    child: Text(data['grade_level'] ?? '')),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for instructors without adviser status
  Widget _buildInstructorWithoutAdviserDrawer(DocumentSnapshot doc) {
    return Container(
      color: Colors.grey[300],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Strand Instructor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 300,
                  child: Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Student',
                        prefixIcon: Icon(Iconsax.search_normal_1_copy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getFilteredInstructorStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs.where((student) {
                    final data = student.data() as Map<String, dynamic>;
                    final query = _searchQuery.toLowerCase();

                    final studentId = data['student_id']?.toLowerCase() ?? '';
                    final firstName = data['first_name']?.toLowerCase() ?? '';
                    final lastName = data['last_name']?.toLowerCase() ?? '';
                    final middleName = data['middle_name']?.toLowerCase() ?? '';
                    final track = data['seniorHigh_Track']?.toLowerCase() ?? '';
                    final strand =
                        data['seniorHigh_Strand']?.toLowerCase() ?? '';

                    final fullName = '$firstName $middleName $lastName';

                    return studentId.contains(query) ||
                        fullName.contains(query) ||
                        track.contains(query) ||
                        strand.contains(query);
                  }).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(value: false, onChanged: (bool? value) {}),
                            Expanded(child: Text('Student ID')),
                            Expanded(child: Text('Name')),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Track'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTrackIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Strand'),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.arrow_drop_down),
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedStrand = value;
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        'ALL',
                                        'STEM',
                                        'HUMSS',
                                        'ABM',
                                        'ICT',
                                        'HE',
                                        'IA'
                                      ].map((String strand) {
                                        return PopupMenuItem<String>(
                                          value: strand,
                                          child: Text(strand),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Grade Level'),
                                  GestureDetector(
                                    onTap:
                                        _toggleGradeLevelIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: Text('Average')),
                          ],
                        ),
                        Divider(),
                        ...students.map((student) {
                          final data = student.data();
                          return Row(
                            children: [
                              Checkbox(
                                  value: false, onChanged: (bool? value) {}),
                              Expanded(child: Text(data['student_id'] ?? '')),
                              Expanded(
                                  child: Text(
                                      '${data['first_name'] ?? ''} ${data['middle_name'] ?? ''} ${data['last_name'] ?? ''}')),
                              Expanded(
                                  child:
                                      Text(data['seniorHigh_Track'] ?? '')),
                              Expanded(
                                  child:
                                      Text(data['seniorHigh_Strand'] ?? '')),
                              Expanded(
                                  child: Text(data['grade_level'] ?? '')),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewcomersContent() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Manage Newcomers',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Student',
                      prefixIcon: Icon(Iconsax.search_normal_1_copy),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getNewcomersStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs.where((student) {
                    final data = student.data() as Map<String, dynamic>;
                    final query = _searchQuery.toLowerCase();

                    final studentId = data['student_id']?.toLowerCase() ?? '';
                    final firstName = data['first_name']?.toLowerCase() ?? '';
                    final lastName = data['last_name']?.toLowerCase() ?? '';
                    final middleName = data['middle_name']?.toLowerCase() ?? '';
                    final track = data['seniorHigh_Track']?.toLowerCase() ?? '';
                    final strand =
                        data['seniorHigh_Strand']?.toLowerCase() ?? '';
                    final gradeLevel = data['grade_level']?.toLowerCase() ?? '';

                    final fullName = '$firstName $middleName $lastName';

                    return studentId.contains(query) ||
                        fullName.contains(query) ||
                        track.contains(query) ||
                        strand.contains(query) ||
                        gradeLevel.contains(query);
                  }).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(value: false, onChanged: (bool? value) {}),
                            Expanded(child: Text('Student ID')),
                            Expanded(child: Text('First Name')),
                            Expanded(child: Text('Last Name')),
                            Expanded(child: Text('Middle Name')),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Track'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTrackIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Strand'),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.arrow_drop_down),
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedStrand = value;
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        'ALL',
                                        'STEM',
                                        'HUMSS',
                                        'ABM',
                                        'ICT',
                                        'HE',
                                        'IA'
                                      ].map((String strand) {
                                        return PopupMenuItem<String>(
                                          value: strand,
                                          child: Text(strand),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Grade Level'),
                                  GestureDetector(
                                    onTap:
                                        _toggleGradeLevelIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        ...students.map((student) {
                          final data = student.data() as Map<String, dynamic>;
                          return Row(
                            children: [
                              Checkbox(
                                  value: false, onChanged: (bool? value) {}),
                              Expanded(child: Text(data['student_id'] ?? '')),
                              Expanded(child: Text(data['first_name'] ?? '')),
                              Expanded(child: Text(data['last_name'] ?? '')),
                              Expanded(child: Text(data['middle_name'] ?? '')),
                              Expanded(
                                  child: Text(data['seniorHigh_Track'] ?? '')),
                              Expanded(
                                  child: Text(data['seniorHigh_Strand'] ?? '')),
                              Expanded(child: Text(data['grade_level'] ?? '')),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Iconsax.tick_circle_copy,
                                          color: Colors.green),
                                      onPressed: () {
                                        approveStudent(student.id);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Iconsax.close_circle_copy,
                                          color: Colors.red),
                                      onPressed: () {
                                        deleteNewComersStudent(student.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageSubjects() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Container(
          color: Colors.grey[300],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Manage Subjects',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    onPressed: toggleAddSubjects,
                    child: Text(
                      'Add New Subject',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  margin: EdgeInsets.all(16),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subjects List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('subjects')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No Subject Added',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              final subjects = snapshot.data!.docs;

                              return Table(
                                border: TableBorder.all(color: Colors.grey),
                                columnWidths: const <int, TableColumnWidth>{
                                  0: FixedColumnWidth(40.0),
                                  1: FlexColumnWidth(),
                                  2: FlexColumnWidth(),
                                  3: FlexColumnWidth(),
                                  4: FlexColumnWidth(),
                                  5: FlexColumnWidth(),
                                  6: FixedColumnWidth(100.0),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('#',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Subject Name',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Code',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Category',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Semester',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Actions',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  // Generate rows dynamically from Firestore
                                  for (var i = 0; i < subjects.length; i++)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text((i + 1).toString()),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child:
                                              Text(subjects[i]['subject_name']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child:
                                              Text(subjects[i]['subject_code']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(subjects[i]['category']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(subjects[i]['semester']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () {
                                                  setState(() {
                                                    selectedSubjectId = subjects[
                                                            i]
                                                        .id; // Store the selected subject's ID
                                                    _showEditSubjects =
                                                        true; // Show the EditSubjectsForm
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_forever,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                _showDeleteSubjectConfirmation(context, subjects[i].id);

                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 550),
          child: _showAddSubjects
              ? Stack(children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: closeAddSubjects,
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
                                child: AddSubjectsForm(
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  key: ValueKey('AddSubjects'),
                                  closeAddSubjects: closeAddSubjects,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ])
              : SizedBox.shrink(),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 550),
          child: _showEditSubjects
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: closeEditSubjects,
                        child: Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                  color: Colors.black.withOpacity(0.5)),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () {},
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 500),
                                  width: screenWidth / 1.2,
                                  height: screenHeight / 1.2,
                                  curve: Curves.easeInOut,
                                  child: EditSubjectsForm(
                                    screenHeight: screenHeight,
                                    screenWidth: screenWidth,
                                    subjectId:
                                        selectedSubjectId, // Pass the selected subject ID
                                    closeEditSubjects: closeEditSubjects,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox.shrink(),
        )
      ],
    );
  }

  Widget _buildManageInstructorContent() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Container(
          color: Colors.grey[300],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Manage Instructors',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    onPressed: toggleAddInstructors,
                    child: Text(
                      'Add New Instructor',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  margin: EdgeInsets.all(16),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructor List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('accountType', isEqualTo: 'instructor')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No Instructor Added',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              final users = snapshot.data!.docs;

                              return SingleChildScrollView(
                                physics: BouncingScrollPhysics(),
                                child: Table(
                                  border: TableBorder.all(color: Colors.grey),
                                  columnWidths: const <int, TableColumnWidth>{
                                    0: FixedColumnWidth(40.0),
                                    1: FlexColumnWidth(),
                                    2: FlexColumnWidth(),
                                    3: FlexColumnWidth(),
                                    4: FlexColumnWidth(),
                                    5: FlexColumnWidth(),
                                    6: FlexColumnWidth(),
                                    7: FlexColumnWidth(),
                                    8: FixedColumnWidth(100.0),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('#',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Instructor Name',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Email Address',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Subjects',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Subject Code',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Adviser',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Handled Section',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Actions',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    // Generate rows dynamically from Firestore
                                    for (var i = 0; i < users.length; i++)
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text((i + 1).toString()),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${users[i]['first_name']} '
                                              '${users[i]['middle_name']?.isNotEmpty == true ? users[i]['middle_name'] + ' ' : ''}'
                                              '${users[i]['last_name']}',
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child:
                                                Text(users[i]['email_Address']),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(users[i]['subject_Name']),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(users[i]['subject_Code']),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(users[i]['adviser']),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(users[i]['handled_section'] ?? 'N/A'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit,
                                                      color: Colors.blue),
                                                  onPressed: () {
                                                    setState(() {
                                                      selectedInstructorId = users[
                                                              i]
                                                          .id; // Store the selected subject's ID
                                                      toggleEditInstructors();
                                                    });
                                                  },
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: DropdownButton<String>(
                                                    value: users[i]['Status'], // Assuming 'status' holds 'active' or 'inactive'
                                                    icon: Icon(Icons.more_vert), // Dropdown icon
                                                    items: <String>['active', 'inactive'].map((String status) {
                                                      return DropdownMenuItem<String>(
                                                        value: status,
                                                        child: Text(status),
                                                      );
                                                    }).toList(),
                                                    onChanged: (String? newStatus) {
                                                      if (newStatus != null && newStatus != users[i]['Status']) {
                                                        _showStatusChangeDialog(context, users[i].id, newStatus); // Call the dialog method
                                                      }
                                                    },
                                                  ),
                                                ),
                                
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 550),
          child: _showAddInstructors
              ? Stack(children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: closeAddInstructors,
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
                                child: AddInstructorDialog(
                                  key: ValueKey('AddInstructor'),
                                  closeAddInstructors: closeAddInstructors,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ])
              : SizedBox.shrink(),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 550),
          child: _showEditInstructors
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: closeEditInstructors,
                        child: Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                  color: Colors.black.withOpacity(0.5)),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () {},
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 500),
                                  width: screenWidth / 1.2,
                                  height: screenHeight / 1.2,
                                  curve: Curves.easeInOut,
                                  child: EditInstructor(
                                    instructorId: selectedInstructorId,
                                    screenHeight: screenHeight,
                                    screenWidth: screenWidth,
                                    closeEditInstructors: closeEditInstructors,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox.shrink(),
        )
      ],
    );
  }

  Widget _buildManageSections() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Container(
          color: Colors.grey[300],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Manage Sections',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    onPressed: toggleAddSections,
                    child: Text(
                      'Add New Sections',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  margin: EdgeInsets.all(16),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sections List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('sections')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No Section Added',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              final sections = snapshot.data!.docs;

                              return Table(
                                border: TableBorder.all(color: Colors.grey),
                                columnWidths: const <int, TableColumnWidth>{
                                  0: FixedColumnWidth(40.0),
                                  1: FlexColumnWidth(),
                                  2: FlexColumnWidth(),
                                  3: FlexColumnWidth(),
                                  4: FlexColumnWidth(),
                                  5: FlexColumnWidth(),
                                  6: FixedColumnWidth(100.0),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('#',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Section Name',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Section Adviser',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Semester',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Section Capacity',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Actions',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  // Generate rows dynamically from Firestore
                                  for (var i = 0; i < sections.length; i++)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text((i + 1).toString()),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child:
                                              Text(sections[i]['section_name']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child:
                                              Text(sections[i]['section_adviser']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(sections[i]['semester']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(sections[i]['section_capacity']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () {
                                                 selectedSectionId = sections[
                                                            i]
                                                        .id;
                                                toggleEditSections();
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_forever,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                _showDeleteSectionConfirmation(context, sections[i].id);

                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 550),
          child: _showAddSections
              ? Stack(children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: closeAddSections,
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
                                child: AddingSections(
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  key: ValueKey('AddSections'),
                                  closeAddSections: closeAddSections,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ])
              : SizedBox.shrink(),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 550),
          child: _showEditSections
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: closeEditSections,
                        child: Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                  color: Colors.black.withOpacity(0.5)),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () {},
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 500),
                                  width: screenWidth / 1.2,
                                  height: screenHeight / 1.2,
                                  curve: Curves.easeInOut,
                                  child: EditSectionsForm(
                                    screenHeight: screenHeight,
                                    screenWidth: screenWidth,
                                    sectionId: selectedSectionId,
                                    key: ValueKey('EditSections'),
                                    closeEditSections: closeEditSections,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox.shrink(),
        )
      ],
    );
  }

  Widget _buildDropStudent() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Dropped Students',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Student',
                      prefixIcon: Icon(Iconsax.search_normal_1_copy),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 2.0),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredDropStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs.where((student) {
                    final data = student.data() as Map<String, dynamic>;
                    final query = _searchQuery.toLowerCase();

                    final studentId = data['student_id']?.toLowerCase() ?? '';
                    final firstName = data['first_name']?.toLowerCase() ?? '';
                    final lastName = data['last_name']?.toLowerCase() ?? '';
                    final middleName = data['middle_name']?.toLowerCase() ?? '';
                    final track = data['seniorHigh_Track']?.toLowerCase() ?? '';
                    final strand =
                        data['seniorHigh_Strand']?.toLowerCase() ?? '';
                    final gradeLevel = data['grade_level']?.toLowerCase() ?? '';

                    final fullName = '$firstName $middleName $lastName';

                    return studentId.contains(query) ||
                        fullName.contains(query) ||
                        track.contains(query) ||
                        strand.contains(query) ||
                        gradeLevel.contains(query);
                  }).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(value: false, onChanged: (bool? value) {}),
                            Expanded(child: Text('Student ID')),
                            Expanded(child: Text('First Name')),
                            Expanded(child: Text('Last Name')),
                            Expanded(child: Text('Middle Name')),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Track'),
                                  GestureDetector(
                                    onTap:
                                        _toggleTrackIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_trackIconState == 0 ||
                                            _trackIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Strand'),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.arrow_drop_down),
                                    onSelected: (String value) {
                                      setState(() {
                                        _selectedStrand = value;
                                      });
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        'ALL',
                                        'STEM',
                                        'HUMSS',
                                        'ABM',
                                        'ICT',
                                        'HE',
                                        'IA'
                                      ].map((String strand) {
                                        return PopupMenuItem<String>(
                                          value: strand,
                                          child: Text(strand),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Grade Level'),
                                  GestureDetector(
                                    onTap:
                                        _toggleGradeLevelIcon, // Handles the tap to change icons
                                    child: Row(
                                      children: [
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                1) // Show up arrow for state 0 and 1
                                          Icon(Iconsax.arrow_up_3_copy,
                                              size: 16),
                                        if (_gradeLevelIconState == 0 ||
                                            _gradeLevelIconState ==
                                                2) // Show down arrow for state 0 and 2
                                          Icon(Iconsax.arrow_down_copy,
                                              size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: Text('Date')),
                            Expanded(child: Text('')),
                            
                          ],
                        ),
                        Divider(),
                        ...students.map((student) {
                          final data = student.data() as Map<String, dynamic>;
                          return Row(
                            children: [
                              Checkbox(
                                  value: false, onChanged: (bool? value) {}),
                              Expanded(child: Text(data['student_id'] ?? '')),
                              Expanded(child: Text(data['first_name'] ?? '')),
                              Expanded(child: Text(data['last_name'] ?? '')),
                              Expanded(child: Text(data['middle_name'] ?? '')),
                              Expanded(
                                  child: Text(data['seniorHigh_Track'] ?? '')),
                              Expanded(
                                  child: Text(data['seniorHigh_Strand'] ?? '')),
                              Expanded(child: Text(data['grade_level'] ?? '')),
                              Expanded(child: Text('Date')),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    showConfirmationDropDialog(context, data['student_id']);
                                  },
                                  style: ButtonStyle(
                                    // Remove any elevation and shadows
                                    elevation: MaterialStateProperty.all(0),
                                    shadowColor: MaterialStateProperty.all(Colors.transparent),
                                    // Ensure no overlay color on hover
                                    overlayColor: MaterialStateProperty.all(Colors.transparent), 
                                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20), // Maintain rounded corners
                                      ),
                                    ),
                                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.hovered)) {
                                          return Colors.green; // Change text color to black on hover
                                        }
                                        return Colors.red; // Default text color
                                      },
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Reactivate',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          SizedBox(width: 4),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
  return Container(
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: Text(
      'Report Analytics',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0), // Set the preferred height
        child: AppBar(
          automaticallyImplyLeading: false, // Remove the back button
          backgroundColor:
              Colors.white, // Set the background color to match the image
          title: Padding(
            padding: const EdgeInsets.only(
                left: 16.0, top: 16.0, bottom: 16.0, right: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  iconSize: 30,
                  icon: Icon(Iconsax.menu_copy,
                      color: Colors.blue), // Use Iconsax.menu
                  onPressed: () {
                    _scaffoldKey.currentState
                        ?.openDrawer(); // Open the drawer when pressed
                  },
                ),
                Row(
                  children: [
                    Icon(
                      size: 30,
                      Iconsax.profile_circle_copy,
                    ),
                    SizedBox(
                        width: 15), // Add spacing between the icon and the text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_accountType',
                          style: TextStyle(
                            color: Colors.black, // Black color for the text
                            fontSize: 16, // Smaller font size for the label
                            fontWeight: FontWeight.bold, // Bold text
                          ),
                        ),
                        Text(
                          _email,
                          style: TextStyle(
                            color: Colors.black, // Black color for the text
                            fontSize: 14, // Smaller font size for the email
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
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/PBMA.png', // Replace with your asset image path
                    height: 130,
                  ),
                ],
              ),
            ),
            _buildDrawerItem('Dashboard', Iconsax.dash_dash, 'Dashboard'),
            _buildDrawerItem('Students', Iconsax.user, 'Students'),
            _buildDrawerItem('Strand Instructor', Iconsax.teacher, 'Strand Instructor'),
            _buildDrawerItem('Manage Newcomers', Iconsax.task, 'Manage Newcomers'),
            _buildDrawerItem('Manage Subjects', Iconsax.activity, 'Manage Subjects'),
            _buildDrawerItem('Manage Instructors', Iconsax.user, 'Manage Instructors'),
            _buildDrawerItem('Manage Sections', Iconsax.user, 'Manage Sections'),
            _buildDrawerItem('Dropped Student', Iconsax.dropbox_copy, 'Dropped Student'),
            _buildDrawerItem('Report Analytics', Iconsax.data_copy, 'Report Analytics'),
            ListTile(
              leading: Icon(Iconsax.logout),
              title: Text('Log out'),
              onTap: () {
                // Show confirmation dialog before logging out
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      ),
                      title: Text('Logout Confirmation'),
                      content: Text('Are you sure you want to do logout?'),
                      actions: <Widget>[
                        // Confirm button
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            // Navigate to the Launcher (or perform actual logout)
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Launcher()),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue, // Blue background
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            'Confirm',
                            style: TextStyle(color: Colors.white), // White text
                          ),
                        ),
                        // Cancel button
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          style: TextButton.styleFrom(
                            side: BorderSide(color: Colors.blue), // Blue border
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.blue), // Blue text
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: _buildBodyContent(),
    );
  }
}
