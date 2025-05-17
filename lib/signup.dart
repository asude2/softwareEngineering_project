import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth'ı import edin

class KayitSayfasi extends StatefulWidget {
  const KayitSayfasi({super.key});

  @override
  _KayitSayfasiState createState() => _KayitSayfasiState();
}

class _KayitSayfasiState extends State<KayitSayfasi> {
  final TextEditingController adController = TextEditingController();
  final TextEditingController soyadController = TextEditingController();
  final TextEditingController numaraController = TextEditingController();
  final TextEditingController tcController = TextEditingController();
  final TextEditingController gmailController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();

  String genelHataMesaji = ""; // Firebase'den gelen hatalar için
  String gmailHataMesaji = "";
  String tcHataMesaji = "";
  String numaraHataMesaji = "";
  String sifreHataMesaji = "";

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  bool isValidTC(String tc) {
    return RegExp(r'^\d{11}$').hasMatch(tc);
  }

  bool isValidSifre(String sifre) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$').hasMatch(sifre);
  }

  bool isValidNumara(String numara) {
    return RegExp(r'^\d{11}$').hasMatch(numara);
  }

  // FirebaseAuth örneğini alalım
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> firebaseKayitOl() async {
    setState(() {
      genelHataMesaji = ""; // Her denemede önceki hatayı temizle
    });
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: gmailController.text.trim(),
        password: sifreController.text.trim(),
      );

      // Kullanıcı başarıyla oluşturuldu.
      // İsterseniz burada kullanıcı bilgilerini Firestore'a kaydedebilirsiniz.
      print("Kullanıcı oluşturuldu: ${userCredential.user?.uid}");
      print("Ad: ${adController.text}");
      print("Soyad: ${soyadController.text}");
      print("Numara: ${numaraController.text}");
      print("TC Kimlik: ${tcController.text}");

      // Kayıt başarılı olduktan sonra kullanıcıyı başka bir sayfaya yönlendirebilirsiniz
      // Örneğin ana sayfaya veya giriş yapılmış bir profil sayfasına
      Navigator.pop(context); // Şimdilik kayıt sayfasını kapatıyoruz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt başarılı!")),
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          sifreHataMesaji = 'Şifre çok zayıf.';
        } else if (e.code == 'email-already-in-use') {
          gmailHataMesaji = 'Bu e-posta adresi zaten kullanılıyor.';
        } else {
          genelHataMesaji = 'Bir hata oluştu: ${e.message}';
        }
        print('Firebase Kayıt Hatası: ${e.code} - ${e.message}');
      });
    } catch (e) {
      setState(() {
        genelHataMesaji = 'Beklenmedik bir hata oluştu: $e';
        print('Genel Kayıt Hatası: $e');
      });
    }
  }

  void kontrolEtVeKayitOl() {
    String gmail = gmailController.text.trim();
    String tc = tcController.text.trim();
    String numara = numaraController.text.trim();
    String sifre = sifreController.text.trim();
    bool formGecerli = true;

    setState(() {
      // Önceki hataları temizle
      gmailHataMesaji = "";
      tcHataMesaji = "";
      numaraHataMesaji = "";
      sifreHataMesaji = "";
      genelHataMesaji = "";

      if (!isValidEmail(gmail)) {
        gmailHataMesaji = "Geçerli bir e-posta adresi girin!";
        formGecerli = false;
      }
      if (!isValidNumara(numara)) {
        numaraHataMesaji = "Lütfen geçerli bir telefon numarası girin";
        formGecerli = false;
      }
      if (!isValidTC(tc)) {
        tcHataMesaji = "TC Kimlik numarası 11 haneli ve sadece sayılardan oluşmalıdır!";
        formGecerli = false;
      }
      if (!isValidSifre(sifre)) {
        sifreHataMesaji = "En az 6 haneli olmalıdır. En az bir harf ve bir rakamdan oluşmalıdır.";
        formGecerli = false;
      }
      if (adController.text.trim().isEmpty) {
        // Ad için hata mesajı eklenebilir
        formGecerli = false;
      }
      if (soyadController.text.trim().isEmpty) {
        // Soyad için hata mesajı eklenebilir
        formGecerli = false;
      }
    });

    if (formGecerli) {
      firebaseKayitOl();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Uzun formlar için kaydırma özelliği
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (Ad, Soyad, Numara, TC TextField'ları olduğu gibi kalabilir)
              // Sadece hata mesajlarını kontrol edin
              Text("Ad:", style: TextStyle(fontSize: 16)),
              TextField(
                controller: adController,
                decoration: InputDecoration(
                  hintText: "Adınızı girin",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),

              Text("Soyad:", style: TextStyle(fontSize: 16)),
              TextField(
                controller: soyadController,
                decoration: InputDecoration(
                  hintText: "Soyadınızı girin",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),

              Text("Numara:", style: TextStyle(fontSize: 16)),
              TextField(
                controller: numaraController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Telefon numaranızı girin",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: numaraHataMesaji.isNotEmpty ? numaraHataMesaji : null,
                ),
              ),
              SizedBox(height: 20),

              Text("TC Kimlik No:", style: TextStyle(fontSize: 16)),
              TextField(
                controller: tcController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "TC Kimlik numarasını girin",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: tcHataMesaji.isNotEmpty ? tcHataMesaji : null,
                ),
              ),
              SizedBox(height: 20),

              Text("Gmail:", style: TextStyle(fontSize: 16)),
              TextField(
                controller: gmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Gmail adresinizi girin",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: gmailHataMesaji.isNotEmpty ? gmailHataMesaji : null,
                ),
              ),
              SizedBox(height: 20),

              Text("Şifre:", style: TextStyle(fontSize: 16)),
              TextField(
                controller: sifreController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Şifre oluşturun",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: sifreHataMesaji.isNotEmpty ? sifreHataMesaji : null,
                ),
              ),
              SizedBox(height: 10),
              if (genelHataMesaji.isNotEmpty) // Genel hata mesajını göster
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
                  onPressed: kontrolEtVeKayitOl, // Firebase'e kayıt fonksiyonunu çağır
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  ),
                  child: Text(
                    "Kayıt Ol",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}