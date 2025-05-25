import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final List<String> avatarList = [
  // Erkek
  'https://cdn-icons-png.flaticon.com/512/4140/4140052.png',
  'https://cdn-icons-png.flaticon.com/512/3800/3800457.png',
  'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
  // Kadın
  'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
  'https://cdn-icons-png.flaticon.com/512/4139/4139977.png',
  'https://cdn-icons-png.flaticon.com/512/1593/1593179.png',
];



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
          if (kullanici.emailVerified) {
            await _firestore.collection("users").doc(kullanici.uid).update({
              "email": kullanici.email,
            });
          }

          setState(() {
            kullaniciVerisi = snapshot.data() as Map<String, dynamic>;
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

  Future<String?> _yeniSifreAl(BuildContext context) async {
    TextEditingController yeniSifreController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Yeni Şifre"),
          content: TextField(
            controller: yeniSifreController,
            obscureText: true,
            decoration: InputDecoration(hintText: "Yeni şifre"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, yeniSifreController.text.trim()),
              child: Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _avatarSecDialog(BuildContext context) async {
    final List<String> avatarList = [
      'https://cdn-icons-png.flaticon.com/512/4140/4140052.png',
      'https://cdn-icons-png.flaticon.com/512/3800/3800457.png',
      'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
      'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
      'https://cdn-icons-png.flaticon.com/512/4139/4139977.png',
      'https://cdn-icons-png.flaticon.com/512/1593/1593179.png',
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Avatar Seç"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: avatarList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  String selectedAvatar = avatarList[index];
                  await _firestore.collection("users").doc(_auth.currentUser!.uid).update({
                    "avatar": selectedAvatar,
                  });
                  setState(() {
                    kullaniciVerisi!['avatar'] = selectedAvatar;
                  });
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(avatarList[index]),
                  radius: 30,
                ),
              );
            },
          ),
        ),
      ),
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

                  }
                  if (alan == "sifre") {
                    // Eski şifreyi sor
                    String? eskiSifre = await _sifreSorDialog(context);
                    if (eskiSifre == null) return;

                    // Yeni şifreyi al
                    String? yeniSifre = await _yeniSifreAl(context);
                    if (yeniSifre == null) return;

                    // Re-authenticate
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: _auth.currentUser!.email!,
                      password: eskiSifre,
                    );

                    await _auth.currentUser!.reauthenticateWithCredential(credential);

                    // Yeni şifreyi güncelle
                    await _auth.currentUser!.updatePassword(yeniSifre);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Şifre başarıyla güncellendi.")),
                    );
                  }
                  else {
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
        title: const Text('Profil Sayfası'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: yukleniyor
          ? Center(child: CircularProgressIndicator())
          : kullaniciVerisi == null
          ? Center(child: Text("Kullanıcı verisi bulunamadı."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar gösterimi
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: kullaniciVerisi!['avatar'] != null
                      ? NetworkImage(kullaniciVerisi!['avatar'])
                      : null,
                  child: kullaniciVerisi!['avatar'] == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _avatarSecDialog(context),
                  child: const Text("Avatar Seç"),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Bilgi kutuları
            bilgiKutusu("Ad Soyad", "${kullaniciVerisi!['ad']} ${kullaniciVerisi!['soyad']}", "ad soyad"),
            bilgiKutusu("Telefon", kullaniciVerisi!['numara'], "numara"),
            bilgiKutusu("TC Kimlik No", kullaniciVerisi!['tcKimlik'], "tcKimlik"),
            bilgiKutusu("Email", kullaniciVerisi!['email'], "email"),
            bilgiKutusu("Şifre", "********", "sifre"),
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
