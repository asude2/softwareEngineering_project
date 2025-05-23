import 'package:depsis_project/personalPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  _GirisSayfasiState createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final TextEditingController gmailController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();

  String genelHataMesaji = "";
  String gmailHataMesaji = "";
  String sifreHataMesaji = "";

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  // Şifre için basit bir kontrol, Firebase daha detaylı kontrol edecektir.
  bool isValidSifre(String sifre) {
    return sifre.isNotEmpty && sifre.length >= 6;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> firebaseGirisYap() async {
    setState(() {
      genelHataMesaji = "";
    });
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: gmailController.text.trim(),
        password: sifreController.text.trim(),
      );
      print("Kullanıcı giriş yaptı: ${userCredential.user?.uid}");

      // Giriş başarılı, kullanıcıyı ana uygulama ekranına yönlendir
      Navigator.pushReplacement( // Geri tuşuyla giriş sayfasına dönmemesi için
        context,
        MaterialPageRoute(builder: (context) => KisiselSayfa()), // Ya da istediğiniz bir ana sayfa
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          genelHataMesaji = 'E-posta veya şifre hatalı.';
        } else if (e.code == 'invalid-email') {
          gmailHataMesaji = 'Geçersiz e-posta formatı.';
        }
        else {
          genelHataMesaji = 'Giriş sırasında bir hata oluştu: ${e.message}';
        }
        print('Firebase Giriş Hatası: ${e.code} - ${e.message}');
      });
    } catch (e) {
      setState(() {
        genelHataMesaji = 'Beklenmedik bir hata oluştu: $e';
        print('Genel Giriş Hatası: $e');
      });
    }
  }


  void kontrolEtVeGirisYap() {
    String gmail = gmailController.text.trim();
    String sifre = sifreController.text.trim();
    bool formGecerli = true;

    setState(() {
      gmailHataMesaji = "";
      sifreHataMesaji = "";
      genelHataMesaji = "";

      if (!isValidEmail(gmail)) {
        gmailHataMesaji = "Geçerli bir e-posta adresi girin!";
        formGecerli = false;
      }
      if (!isValidSifre(sifre)) { // Şifre için temel geçerlilik kontrolü
        sifreHataMesaji = "Şifre en az 6 karakter olmalıdır.";
        formGecerli = false;
      }
    });

    if (formGecerli) {
      firebaseGirisYap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 28),
            Text("Gmail:", style: TextStyle(fontSize: 20)),
            TextField(
              controller: gmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Gmail adresinizi girin",
                hintStyle: TextStyle(fontSize:18),
                contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                errorText: gmailHataMesaji.isNotEmpty ? gmailHataMesaji : null,
              ),
            ),
            SizedBox(height: 20),
            Text("Şifre:", style: TextStyle(fontSize: 20)),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Şifrenizi girin",
                hintStyle: TextStyle(fontSize:18),
                contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: sifreHataMesaji.isNotEmpty ? sifreHataMesaji : null,
              ),
            ),
            SizedBox(height: 10),
            if (genelHataMesaji.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  genelHataMesaji,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            SizedBox(height: 25),
            Center(
              child: ElevatedButton(
                onPressed: kontrolEtVeGirisYap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 80, vertical: 18),
                ),
                child: Text(
                  "Giriş Yap",
                  style: TextStyle(color: Colors.white, fontSize:20, fontWeight: FontWeight.bold,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}