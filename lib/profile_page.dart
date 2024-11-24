import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'login.dart';
import 'addeditpage.dart';
import 'custom_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginRequiredNotification(context));
    }

    void navigateToAddEditPage() {
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
        decoration: const BoxDecoration(
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
                  textStyle: const TextStyle(
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
                    ? const Text(
                        'Please log in to view this page.',
                        style: TextStyle(color: Colors.white),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50,),
                          const CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage('assets/profile_pic.jpg'),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            user.displayName ?? 'No Name',
                            style: GoogleFonts.quicksand(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                                      const Icon(Icons.person, size: 24, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        user.displayName ?? 'No Name',
                                        style: const TextStyle(fontSize: 15.0, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.email, size: 24, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        user.email ?? 'No Email',
                                        style: const TextStyle(fontSize: 15.0, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7D28FD), // Button background color
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
              child: CustomNavigationBar(
                currentIndex: 2,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
                      break;
                    case 1:
                      navigateToAddEditPage();
                      break;
                    case 2:
                      // Add your page navigation here
                      break;
                  }
                },
                onAddLog: navigateToAddEditPage,
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
        title: const Text('Login Required'),
        content: const Text('You need to log in to view this page.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Login'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
