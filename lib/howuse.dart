import 'package:flutter/material.dart';

class NasilKullanilir extends StatelessWidget {
  const NasilKullanilir({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nasıl Kullanılır?"),
        foregroundColor:Colors.white,
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
            Image(
              image: AssetImage('assets/usageInfo.png'),
            ),

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
                    Icon(Icons.arrow_back, color:Colors.white, size:30,),
                    SizedBox(width: 20),
                    Text(
                      'Ana Sayfaya Dön',
                      style: TextStyle(
                        color: Colors.white, fontSize: 18,
                      ),
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