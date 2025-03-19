import 'package:flutter/material.dart';

class NasilKullanilir extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bilgi Sayfası")),
      body: Center(
        child: Text(
          "Burası Bilgi Sayfası",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
