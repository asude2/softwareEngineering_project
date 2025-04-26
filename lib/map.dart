import 'package:flutter/material.dart';


class HaritaSayfasi extends StatelessWidget {
  const HaritaSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Harita")),
      body: Center(
        child: Text(
          "Burası Harita Sayfası",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}