import 'package:flutter/material.dart';

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


  String gmailHataMesaji = "";
  String tcHataMesaji = "";
  String numaraHataMesaji = "";
  String sifreHataMesaji = "";

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  bool isValidTC(String tc) {
    return RegExp(r'^\d{11}$').hasMatch(tc);  //içermesi gereken karakterleri yazdık.
  }

  bool isValidSifre(String sifre) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$').hasMatch(sifre);
  }

  bool isValidNumara(String numara) {
    return RegExp(r'^\d{11}$').hasMatch(numara);
  }


  void kontrolEt() {
    String gmail = gmailController.text;
    String tc = tcController.text;
    String numara = numaraController.text;
    String sifre = sifreController.text;

    setState(() {
      if (!isValidEmail(gmail)) {
        gmailHataMesaji = "Geçerli bir e-posta adresi girin!";
      } else {
        gmailHataMesaji = "";
      }

      if(!isValidNumara(numara)){
        numaraHataMesaji = "Lütfen geçerli bir telefon numarsı girin";
      }
      else {
        numaraHataMesaji = "";
      }

      if (!isValidTC(tc)) {
        tcHataMesaji = "TC Kimlik numarası 11 haneli ve sadece sayılardan oluşmalıdır!";
      } else {
        tcHataMesaji = "";
      }

      if (!isValidSifre(sifre)) {
        sifreHataMesaji = "En az 6 haneli olmalıdır. En az bir harf ve bir rakamdan oluşmalıdır.";
      } else {
        sifreHataMesaji = "";
      }

      // Eğer her şey doğruysa, giriş bilgilerini konsola yazdır
      if (gmailHataMesaji.isEmpty && tcHataMesaji.isEmpty && sifreHataMesaji.isEmpty && numaraHataMesaji.isEmpty) {
        print("Ad: ${adController.text}");
        print("Soyad: ${soyadController.text}");
        print("Numara: $numara");
        print("TC Kimlik: $tc");
        print("Gmail: $gmail");
        print("Şifre: $sifre");

        // Başka bir sayfaya yönlendirme işlemi burada yapılabilir
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15),
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
              obscureText: true, // Şifreyi gizler
              decoration: InputDecoration(
                hintText: "Şifre oluşturun",
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
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                ), // Butona basınca kontrolEt() fonksiyonu çalışacak
                child: Text(
                  "Kayıt Ol",
                  style: TextStyle(color: Colors.white, fontSize:16, fontWeight: FontWeight.bold,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}