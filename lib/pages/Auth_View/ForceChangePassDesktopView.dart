import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pbma_portal/Accounts/student_dashboard.dart';
import 'package:pbma_portal/student_utils/student_ui.dart';

class ChangePasswordDesktop extends StatefulWidget {
  final String email;

  const ChangePasswordDesktop({super.key, required this.email});

  @override
  _ChangePasswordDesktopState createState() => _ChangePasswordDesktopState();
}

class _ChangePasswordDesktopState extends State<ChangePasswordDesktop> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureTextNew = true;
  bool _obscureTextConfirm = true;
  bool _passwordMismatch = false;

  void _togglePasswordVisibilityNew() {
    setState(() {
      _obscureTextNew = !_obscureTextNew;
    });
  }

  void _togglePasswordVisibilityConfirm() {
    setState(() {
      _obscureTextConfirm = !_obscureTextConfirm;
    });
  }

  Future<void> _changePassword() async {
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showDialog('Empty Field',
          'Please enter both new password and confirm password.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordMismatch = true;
      });
      return;
    }

    RegExp passwordRegex = RegExp(
      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~_-]).{8,}$',
    );

    if (!passwordRegex.hasMatch(newPassword)) {
      _showDialog('Weak Password',
          'Password must contain at least 8 characters, including uppercase letters, lowercase letters, numbers, and symbols.');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);

        final uid = user.uid;
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: uid)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _showDialog('Error', 'No document found with the provided UID.');
          return;
        }

        final document = querySnapshot.docs.first;
      final documentId = document.id;
      final firstName = document['first_name'] as String;
      final middleName = document['middle_name'] as String;
      final lastName = document['last_name'] as String;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(documentId)
            .update({
          'passwordChanged': true,
        }).catchError((error) {
          print('Failed to update document: $error');
          _showDialog(
              'Error', 'Failed to update document: ${error.toString()}');
        });

        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentUI(),
        ),
      );
    }
  } catch (error) {
    _showDialog('Error', 'Failed to change password: ${error.toString()}');
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Container(
        width: screenWidth / 2,
        height: screenHeight / 1.2,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 550),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/PBMA.png',
                      width: screenWidth / 7,
                      height: screenHeight / 3,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                       padding: const EdgeInsets.only(left: 80.0),
                      child: Text(
                        'Change Password',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                       padding: const EdgeInsets.only(left: 80.0),
                      child: Text(
                        'Before you proceed please kindly change your password',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: screenHeight / 13,
                    width: screenWidth / 2.57,
                    child: CupertinoTextField(
                      controller: _newPasswordController,
                      placeholder: 'Password',
                      obscureText: _obscureTextNew,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey.shade300,
                      ),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Icon(Icons.lock_outline),
                      ),
                      suffix: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureTextNew = !_obscureTextNew;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 10.0),
                          child: Icon(
                            _obscureTextNew
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: screenHeight / 13,
                    width: screenWidth / 2.57,
                    child: CupertinoTextField(
                      controller: _confirmPasswordController,
                      placeholder: 'Password',
                      obscureText: _obscureTextConfirm,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey.shade300,
                      ),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Icon(Icons.lock_outline),
                      ),
                      suffix: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureTextConfirm = !_obscureTextConfirm;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 10.0),
                          child: Icon(
                            _obscureTextConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: screenHeight / 20,
                            width: screenWidth / 2.57,
                    child: ElevatedButton(
                      style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.deepPurpleAccent),
                                    elevation:
                                        MaterialStateProperty.all<double>(5),
                                    shape:
                                        MaterialStateProperty.all<OutlinedBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                      onPressed: _changePassword,
                      child: Text('Change Password',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),),
                    ),
                  ),
                  if (_passwordMismatch)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Passwords do not match',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
