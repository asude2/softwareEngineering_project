import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  String adSoyad = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data();
        String ad = data?['ad'] ?? "";
        String soyad = data?['soyad'] ?? "";
        setState(() {
          adSoyad = "$ad $soyad";
          loading = false;
        });
      } else {
        setState(() {
          adSoyad = "Kullanıcı bilgisi bulunamadı";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        adSoyad = "Bilgi alınamadı";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String email = user?.email ?? "Bilinmeyen";

    return Scaffold(
      appBar: AppBar(
        title: Text("Kişisel Sayfa"),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: loading
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "Hoş geldin $adSoyad!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Giriş yapan kullanıcı: $email",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                print("İhbar oluştur butonuna tıklandı!");
                // Yeni sayfaya geçiş buraya
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text("İhbar Oluştur", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text("Çıkış Yap", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
