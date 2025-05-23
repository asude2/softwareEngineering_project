import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Sayfası'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Text(
          'Profil sayfasına hoş geldiniz!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
