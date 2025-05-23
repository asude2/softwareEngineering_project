import 'package:depsis_project/main.dart';
import 'package:depsis_project/menu.dart';
import 'package:depsis_project/profilePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'city_district_data.dart';
import 'edit_not.dart';

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
  bool isEditing = false;
  String? editingDocId;

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

  Future<void> loadLastReport() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('ihbarlar')
        .where('ihbar_eden_uid', isEqualTo: uid)
        .orderBy('tarih', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();

      setState(() {
        isEditing = true;
        editingDocId = doc.id;
        showForm = true;

        adSoyadController.text = data['ihbar_edilen_ad_soyad'] ?? '';
        telController.text = data['telefon'] ?? '';
        tcController.text = data['tc'] ?? '';
        detayliAdresController.text = data['detayli_adres'] ?? '';
        seciliIl = data['il'] ?? '';
        seciliIlce = data['ilce'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiç ihbar bulunamadı')),
      );
    }
  }

  Future<void> submitReport() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final reportData = {
      'ihbar_eden_uid': uid,
      'ihbar_edilen_ad_soyad': adSoyadController.text,
      'telefon': telController.text,
      'tc': tcController.text,
      'il': seciliIl,
      'ilce': seciliIlce,
      'detayli_adres': detayliAdresController.text,
      'tarih': Timestamp.now(),
    };

    if (isEditing && editingDocId != null) {
      await FirebaseFirestore.instance.collection('ihbarlar').doc(editingDocId).update(reportData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İhbar güncellendi')));
    } else {
      await FirebaseFirestore.instance.collection('ihbarlar').add(reportData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İhbar gönderildi')));
    }

    setState(() {
      showForm = false;
      isEditing = false;
      editingDocId = null;
      adSoyadController.clear();
      telController.clear();
      tcController.clear();
      detayliAdresController.clear();
      seciliIl = '';
      seciliIlce = '';
    });
  }

  Widget buildForm() {
    return Column(
      children: [
        SizedBox(height: 30),
        TextField(controller: adSoyadController, decoration: _inputDecoration('Ad Soyad')),
        SizedBox(height: 15),
        TextField(controller: telController, decoration: _inputDecoration('Telefon Numarası'), keyboardType: TextInputType.phone),
        SizedBox(height: 15),
        TextField(controller: tcController, decoration: _inputDecoration('TC Kimlik No'), keyboardType: TextInputType.number),
        SizedBox(height: 15),
        DropdownButtonFormField<String>(
          decoration: _inputDecoration('İl seçin'),
          value: seciliIl.isEmpty ? null : seciliIl,
          onChanged: (value) => setState(() => seciliIl = value ?? ''),
          items: iller.map((il) => DropdownMenuItem(value: il, child: Text(il))).toList(),
        ),
        SizedBox(height: 15),
        DropdownButtonFormField<String>(
          decoration: _inputDecoration('İlçe seçin'),
          value: seciliIlce.isEmpty ? null : seciliIlce,
          onChanged: (value) => setState(() => seciliIlce = value ?? ''),
          items: (ilceler[seciliIl] ?? []).map((ilce) => DropdownMenuItem(value: ilce, child: Text(ilce))).toList(),
        ),
        SizedBox(height: 15),
        TextField(controller: detayliAdresController, decoration: _inputDecoration('Detaylı Adres'), maxLines: 2),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: submitReport,
          child: Text(isEditing ? 'Güncelle' : 'Gönder'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(labelText: label, border: OutlineInputBorder());
  }

  void cikisYap() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kişisel Sayfa'),
        backgroundColor: Colors.red,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu), // 3 çizgi menü ikonu
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Text(
                '$ad $soyad',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profil'),
              onTap: () {
                Navigator.pop(context); // Drawer kapansın
                // Profil sayfasına yönlendir (örnek olarak EditNot sayfası)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()), // Profil sayfan varsa buraya yaz
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Çıkış Yap'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AnaSayfa()), // giriş/kayıt sayfanın adı
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Hoş Geldiniz, ', style: TextStyle(fontSize: 20)),
            TextSpan(text: '$ad $soyad', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ])),
          SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => {showForm = true, isEditing = false}),
                  icon: Icon(Icons.report_problem),
                  label: Text('İhbar Oluştur'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IhbarDuzenleSayfasi()),
                    );
                  },
                  icon: Icon(Icons.edit),
                  label: Text('İhbar Düzenle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
          if (showForm) buildForm(),
        ]),
      ),
    );
  }
}