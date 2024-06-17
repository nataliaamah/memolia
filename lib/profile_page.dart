import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'login.dart';
import 'addeditpage.dart';
import 'custom_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginRequiredNotification(context));
    }

    void _navigateToAddEditPage() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditPage(
            refreshDiaries: () {},
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset("assets/memolia_name.png", height: 200),
        backgroundColor: const Color.fromRGBO(14, 14, 37, 1),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E25), Color(0xFF1C1C50)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Profile Page",
                style: GoogleFonts.quicksand(
                  textStyle: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: user == null
                    ? Text(
                        'Please log in to view this page.',
                        style: TextStyle(color: Colors.white),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(height: 50,),
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage('assets/profile_pic.jpg'),
                          ),
                          SizedBox(height: 20),
                          Text(
                            user.displayName ?? 'No Name',
                            style: GoogleFonts.quicksand(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add padding around the container
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 24, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        user.displayName ?? 'No Name',
                                        style: TextStyle(fontSize: 15.0, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.email, size: 24, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        user.email ?? 'No Email',
                                        style: TextStyle(fontSize: 15.0, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 50),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => HomePage()),
                              );
                            },
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7D28FD), // Button background color
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 30, right: 30, bottom: 10),
              child: CustomNavigationBar(
                currentIndex: 2,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                      break;
                    case 1:
                      _navigateToAddEditPage();
                      break;
                    case 2:
                      // Add your page navigation here
                      break;
                  }
                },
                onAddLog: _navigateToAddEditPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required'),
        content: Text('You need to log in to view this page.'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Login'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
