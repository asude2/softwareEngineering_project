import 'package:flutter/material.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  _GirisSayfasiState createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final TextEditingController gmailController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();


  String gmailHataMesaji = "";
  String sifreHataMesaji = "";

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  bool isValidSifre(String sifre) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$').hasMatch(sifre);
  }

  void kontrolEt() {
    String gmail = gmailController.text;
    String sifre = sifreController.text;

    setState(() {
      if (!isValidEmail(gmail)) {
        gmailHataMesaji = "Geçerli bir e-posta adresi girin!";
      } else {
        gmailHataMesaji = "";
      }

      if (!isValidSifre(sifre)) {
        sifreHataMesaji = "En az 6 haneli olmalıdır. En az bir harf ve bir rakamdan oluşmalıdır.";
      } else {
        sifreHataMesaji = "";
      }

      // Eğer her şey doğruysa, giriş bilgilerini konsola yazacağız
      if (gmailHataMesaji.isEmpty && sifreHataMesaji.isEmpty) {
        print("Gmail: $gmail");
        print("Şifre: $sifre");

        // Başka bir sayfaya yönlendirme işlemi burada yapılabilir

      }
    });
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
              obscureText: true, // Şifreyi gizler
              decoration: InputDecoration(
                hintText: "Şifrenizi girin",
                hintStyle: TextStyle(fontSize:18),
                contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                errorText: sifreHataMesaji.isNotEmpty ? sifreHataMesaji : null,
              ),
            ),
            SizedBox(height: 35),


            Center(
              child: ElevatedButton(
                onPressed: kontrolEt,
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