import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'homepage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigningIn = false;
  bool _isLoginConfirmed = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '911904224271-lp2ectdmvk1tdnkldvbokpf12932ta36.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7D28FD), Color(0xFFA851F7)], // Purple gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 300),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Text(
                      "Welcome to Memolia",
                      style: TextStyle(
                        fontSize: 29,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!_isLoginConfirmed)
                      _isSigningIn
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isSigningIn = true;
                          });

                          User? user = await signInWithGoogle();

                          if (mounted) {
                            setState(() {
                              _isSigningIn = false;
                            });

                            if (user != null) {
                              setState(() {
                                _isLoginConfirmed = true;
                              });

                              await Future.delayed(const Duration(seconds: 3));

                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomePage()),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E0E25), // Button color to match previous gradient color
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google_logo.png',
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isLoginConfirmed)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/sparkle.gif', height: 100),
                              Image.asset('assets/check.gif', height: 100, width: 100,),
                              Image.asset('assets/sparkle.gif', height: 100),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            "Login Successful",
                            style: GoogleFonts.quicksand(
                              fontSize: 27,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<User?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      FirebaseAuth.instance.setLanguageCode('en'); // Set locale

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In canceled.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Missing authentication tokens.');
        return null;
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

      print('Sign-In successful for user: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }
}
