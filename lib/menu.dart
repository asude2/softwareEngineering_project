import 'package:flutter/material.dart';

// Menü sayfası (drawer) - 2 buton var
class MenuSayfasi extends StatelessWidget {
  const MenuSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Color(0xFFDC321E),
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Menü',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.white, size: 40),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          // Nasıl Kullanılır butonu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC321E),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NasilKullanilir()),
                );
              },
              child: Text(
                'Nasıl Kullanılır',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Çök - Kapan - Tutun butonu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC321E),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CokKapanTutunSayfasi()),
                );
              },
              child: Text(
                'Çök - Kapan - Tutun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Nasıl Kullanılır sayfası
class NasilKullanilir extends StatelessWidget {
  const NasilKullanilir({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nasıl Kullanılır?"),
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFFDC321E),
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Uygulamayı Kullanma Rehberi",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "1. İhbar oluşturabilmek için kayıt olup sayfanıza giriş yapmalısınız.\n"
                  "2. İhbar haritasını ve listesini görmek için uygulamaya kayıt olmanıza gerek yoktur.\n"
                  "3. Yetkiliyseniz, kurtarılan kişilerin konumlarını ve durumlarını güncelleyebilirsiniz.\n"
                  "4. Haritada kırmızı ile gösterilen konumlar onaylanmış ihbarları, yeşil ile gösterilen konumlar kurtarılan kişileri göstermektedir.\n"
                  "5. Güncellenen konumlar herkes tarafından görülebilir.",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            Image.asset('assets/usageInfo.png'),
            SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    SizedBox(width: 20),
                    Text(
                      'Ana Sayfaya Dön',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Çök - Kapan - Tutun sayfası
class CokKapanTutunSayfasi extends StatelessWidget {
  const CokKapanTutunSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Çök-Kapan-Tutun'),
        backgroundColor: Color(0xFFDC321E),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Deprem Anında Alınması Gereken Pozisyon:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '1. Çök: Dizlerinizin üstüne oturun, yere doğru çökün.\n\n'
                      '2. Kapan: Başınızı ve boynunuzu koruyacak şekilde bir şeyin altına girin.\n\n'
                      '3. Tutun: Yere düşebilecek eşyalardan uzak durun ve bir nesneyi tutarak kendinizi koruyun.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              Image.asset(
                'assets/çkt.jpg',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
