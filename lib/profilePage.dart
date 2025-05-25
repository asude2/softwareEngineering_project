import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? kullaniciVerisi;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    verileriGetir();
  }

  Future<void> verileriGetir() async {
    try {
      User? kullanici = _auth.currentUser;

      if (kullanici != null) {
        DocumentSnapshot snapshot =
        await _firestore.collection('users').doc(kullanici.uid).get();

        if (snapshot.exists) {
          // Kullanıcı doğruladıysa maili firestore ile senkronla
          if (kullanici.emailVerified) {
            await _firestore.collection("users").doc(kullanici.uid).update({
              "email": kullanici.email,
            });
          }

          setState(() {
            kullaniciVerisi = snapshot.data() as Map<String, dynamic>;
            yukleniyor = false;
          });
        } else {
          setState(() {
            yukleniyor = false;
          });
        }
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
      setState(() {
        yukleniyor = false;
      });
    }
  }


  Future<String?> _sifreSorDialog(BuildContext context) async {
    TextEditingController sifreController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Şifrenizi girin"),
          content: TextField(
            controller: sifreController,
            obscureText: true,
            decoration: InputDecoration(hintText: "Şifreniz"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, sifreController.text.trim()),
              child: Text("Devam Et"),
            ),
          ],
        );
      },
    );
  }




  Future<void> bilgiyiGuncelle(String alan, String mevcutDeger) async {
    TextEditingController controller = TextEditingController(text: mevcutDeger);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Güncelle: $alan"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Yeni $alan girin"),
        ),
        actions: [
          TextButton(
            child: Text("İptal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text("Kaydet"),
            onPressed: () async {
              String yeniDeger = controller.text.trim();
              if (yeniDeger.isNotEmpty) {
                try {
                  if (alan == "email") {
                    // Şifreyi al
                    String? sifre = await _sifreSorDialog(context);
                    if (sifre == null) return;

                    // Re-authenticate
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: _auth.currentUser!.email!,
                      password: sifre,
                    );
                    await _auth.currentUser!.reauthenticateWithCredential(credential);

                    // Emaili değiştir (doğrulama linki gönderilecek)
                    await _auth.currentUser!.verifyBeforeUpdateEmail(yeniDeger);

                    // Firestore'daki veriyi de güncelle
                    await _firestore.collection("users").doc(_auth.currentUser!.uid).update({
                      "email": yeniDeger,
                    });

                    // Kullanıcıya bilgi ver
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Yeni e-posta adresinize doğrulama bağlantısı gönderildi. Lütfen mailinizi kontrol edin.",
                        ),
                      ),
                    );

                  } else {
                    // Email değilse doğrudan firestore'da güncelle
                    await _firestore.collection("users").doc(_auth.currentUser!.uid).update({
                      alan: yeniDeger,
                    });

                    // local veriyi güncelle
                    setState(() {
                      kullaniciVerisi![alan] = yeniDeger;
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: ${e.toString()}")),
                  );
                }
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Sayfası'),
        backgroundColor: Colors.red,
      ),
      body: yukleniyor
          ? Center(child: CircularProgressIndicator())
          : kullaniciVerisi == null
          ? Center(child: Text("Kullanıcı verisi bulunamadı."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Fotoğraf kutusu
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(75),
              ),
              child: Center(
                child: Text("Fotoğraf", style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 20),

            // Bilgi kutuları
            bilgiKutusu("Ad Soyad", "${kullaniciVerisi!['ad']} ${kullaniciVerisi!['soyad']}", "ad soyad"),
            bilgiKutusu("Telefon", kullaniciVerisi!['numara'], "numara"),
            bilgiKutusu("TC Kimlik No", kullaniciVerisi!['tcKimlik'], "tcKimlik"),
            bilgiKutusu("Email", kullaniciVerisi!['email'], "email"),
          ],
        ),
      ),
    );
  }

  Widget bilgiKutusu(String baslik, String icerik, String firestoreAlani) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(baslik, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(icerik),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            // Ad Soyad özel durumu
            if (firestoreAlani == "ad soyad") {
              guncelleAdSoyad();
            } else {
              bilgiyiGuncelle(firestoreAlani, icerik);
            }
          },
        ),
      ),
    );
  }

  void guncelleAdSoyad() async {
    TextEditingController adController = TextEditingController(text: kullaniciVerisi!['ad']);
    TextEditingController soyadController = TextEditingController(text: kullaniciVerisi!['soyad']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ad Soyad Güncelle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adController,
              decoration: InputDecoration(labelText: "Ad"),
            ),
            TextField(
              controller: soyadController,
              decoration: InputDecoration(labelText: "Soyad"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              String yeniAd = adController.text.trim();
              String yeniSoyad = soyadController.text.trim();
              if (yeniAd.isNotEmpty && yeniSoyad.isNotEmpty) {
                await _firestore.collection("users").doc(_auth.currentUser!.uid).update({
                  "ad": yeniAd,
                  "soyad": yeniSoyad,
                });
                setState(() {
                  kullaniciVerisi!['ad'] = yeniAd;
                  kullaniciVerisi!['soyad'] = yeniSoyad;
                });
              }
              Navigator.pop(context);
            },
            child: Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}
