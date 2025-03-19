import 'package:flutter/material.dart';

class GirisSayfasi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Giriş Sayfası")),
      body: Center(
        child: Text(
          "Burası Giriş Sayfası",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
