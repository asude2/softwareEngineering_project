import 'package:flutter/material.dart';

class KayitSayfasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kayıt Sayfası")),
      body: Center(
        child: Text(
          "Burası Kayıt Sayfası",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
