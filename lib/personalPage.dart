import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'city_district_data.dart';

class KisiselSayfa extends StatefulWidget {
  const KisiselSayfa({super.key});

  @override
  State<KisiselSayfa> createState() => _KisiselSayfaState();
}

class _KisiselSayfaState extends State<KisiselSayfa> {
  String ad = '';
  String soyad = '';
  bool isLoading = true;
  bool showForm = false;

  final TextEditingController adSoyadController = TextEditingController();
  final TextEditingController telController = TextEditingController();
  final TextEditingController tcController = TextEditingController();
  final TextEditingController detayliAdresController = TextEditingController();

  String seciliIl = '';
  String seciliIlce = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          ad = doc['ad'] ?? '';
          soyad = doc['soyad'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kişisel Sayfa'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hoş Geldiniz, ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: '$ad $soyad',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    showForm = true;
                  });
                },
                icon: Icon(Icons.report_problem_outlined),
                label: Text('İhbar Oluştur', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ),
            if (showForm) ...[
              SizedBox(height: 30),
              TextField(
                controller: adSoyadController,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: telController,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 15),
              TextField(
                controller: tcController,
                decoration: InputDecoration(
                  labelText: 'TC Kimlik No',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'İl seçin',
                  border: OutlineInputBorder(),
                ),
                value: seciliIl.isEmpty ? null : seciliIl,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    seciliIl = value ?? '';
                    seciliIlce = '';
                  });
                },
                items: iller
                    .map((il) => DropdownMenuItem(
                  value: il,
                  child: Text(il),
                ))
                    .toList(),
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'İlçe seçin',
                  border: OutlineInputBorder(),
                ),
                value: seciliIlce.isEmpty ? null : seciliIlce,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    seciliIlce = value ?? '';
                  });
                },
                items: (ilceler[seciliIl] ?? [])
                    .map((ilce) => DropdownMenuItem(
                  value: ilce,
                  child: Text(ilce),
                ))
                    .toList(),
              ),
              SizedBox(height: 15),
              TextField(
                controller: detayliAdresController,
                decoration: InputDecoration(
                  labelText: 'Detaylı Adres (Sokak, bina, daire vs)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    String tamAdres =
                        '$seciliIl, $seciliIlce, ${detayliAdresController.text}';
                    print('İhbar Gönderildi');
                    print('Ad Soyad: ${adSoyadController.text}');
                    print('Telefon: ${telController.text}');
                    print('TC: ${tcController.text}');
                    print('Adres: $tamAdres');

                    // TODO: Firestore'a veri kaydet
                  },
                  child: Text('Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
