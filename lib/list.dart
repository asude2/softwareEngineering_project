import 'package:flutter/material.dart';


class ListeSayfasi extends StatelessWidget {
  const ListeSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("İhbar Listesi")),
      body: Center(
        child: Text(
          "Burası Liste Sayfası",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}