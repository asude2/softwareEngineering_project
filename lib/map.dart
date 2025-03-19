import 'package:flutter/material.dart';


class HaritaSayfasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Harita Sayfası")),
      body: Center(
        child: Text(
          "Burası Harita Sayfası",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
