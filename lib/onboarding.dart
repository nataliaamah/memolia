import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:memolia/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Scaffold(
        body: OnboardingScreen(),
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromRGBO(14, 14, 37, 1),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late PageController _pageViewController;
  late TabController _tabController;
  int _currentPageIndex = 0;

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageViewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // build pageview
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        PageView(
          controller: _pageViewController,
          onPageChanged: _handlePageViewChanged,
          children: [
            buildOnboardingOne(context),
            buildOnboardingTwo(context),
          ],
        ),
        _navigationButtons(),
      ],
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    setState(() {
      _currentPageIndex = currentPageIndex;
    });
  }

  void _updateCurrentPageIndex(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  bool _isOnDesktopAndWeb() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
      default:
        return false;
    }
  }

  // first onboarding
  Widget buildOnboardingOne(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color.fromRGBO(57, 94, 102, 1),
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 51, vertical: 92),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 40),
            Image.asset('assets/track.png', height: 300, width: 500),
            Text(
              "Keep Track of Your Emotions",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(textStyle: const TextStyle(fontSize: 30, color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.w700)),
            ),
            const Spacer(flex: 37),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(bottom: 30), // Adjust padding as needed
              child: SizedBox(
                height: 10,
                child: SmoothPageIndicator(
                  controller: _pageViewController,
                  count: 2,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: Color.fromARGB(255, 255, 255, 255),
                    dotHeight: 10,
                    dotWidth: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // second onboarding
  Widget buildOnboardingTwo(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color.fromRGBO(65, 93, 67, 1),
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 51, vertical: 92),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 40),
            Image.asset('assets/control.png', height: 300, width: 500),
            Text(
              "Take Control Over Your Emotions",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(textStyle: const TextStyle(fontSize: 30, color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.w700)),
            ),
            const Spacer(flex: 37),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(bottom: 30), // Adjust padding as needed
              child: SizedBox(
                height: 10,
                child: SmoothPageIndicator(
                  controller: _pageViewController,
                  count: 2,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: Color.fromARGB(255, 255, 255, 255),
                    dotHeight: 10,
                    dotWidth: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row _leftButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _currentPageIndex -= 1;
            });
            _pageViewController.animateToPage(
              _currentPageIndex,
              duration: const Duration(milliseconds: 250), // Sets duration to 300 milliseconds
              curve: Curves.easeInOut,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 50),
            child: Image.asset('assets/images/nextArrow.png', height: 30, width: 30),
          ),
        ),
      ],
    );
  }

  // arrow back
  Row _navigationButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end of the row
    children: [
      // Only show 'Previous' button if currentPageIndex is greater than 0
      if (_currentPageIndex > 0)
        GestureDetector(
          onTap: () {
            setState(() {
              _currentPageIndex -= 1;
            });
            _pageViewController.animateToPage(
              _currentPageIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 240), // Adjust horizontal padding as needed
            child: Image.asset('assets/backArrow.png', height: 30, width: 30),
          ),
        )
      else
        const SizedBox(width: 50), // Placeholder to maintain alignment

      if (_currentPageIndex < 1) // Show 'Next' button only on first and second screens
        GestureDetector(
          onTap: () {
            setState(() {
              _currentPageIndex += 1;
            });
            _pageViewController.animateToPage(
              _currentPageIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20), // Adjust horizontal padding as needed
            child: Image.asset('assets/nextArrow.png', height: 30, width: 30),
          ),
        )
      else
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20), // Adjust padding as needed
          ),
          child: const Text('Next', style: TextStyle(fontSize: 18, fontFamily: "Roboto", fontWeight: FontWeight.w400, color: Color.fromRGBO(255, 255, 255, 1))),
        ),
    ],
  );
}

}
