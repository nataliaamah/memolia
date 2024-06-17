import 'package:flutter/material.dart';
import 'dart:ui';

class CustomNavigationBar extends StatelessWidget {
  final Function(int) onTap;
  final int currentIndex;
  final VoidCallback onAddLog;

  CustomNavigationBar({required this.onTap, required this.currentIndex, required this.onAddLog});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          height: 60,
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(243, 167, 18, 0.8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.home),
                  color: const Color.fromRGBO(14, 14, 37, 1),
                  onPressed: () => onTap(0),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  iconSize: 28,
                  color: const Color.fromRGBO(14, 14, 37, 1),
                  onPressed: onAddLog,
                ),
                IconButton(
                  icon: Icon(Icons.people_alt_rounded),
                  color: const Color.fromRGBO(14, 14, 37, 1),
                  onPressed: () => onTap(2),
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  color: const Color.fromRGBO(14, 14, 37, 1),
                  onPressed: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
