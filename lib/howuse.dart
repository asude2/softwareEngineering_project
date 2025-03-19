import 'package:flutter/material.dart';


import 'package:flutter/material.dart';

class NasilKullanilir extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nasıl Kullanılır?"),
        foregroundColor:Colors.white,
        backgroundColor: Color(0xFFDC321E),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Uygulamayı Kullanma Rehberi",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "1. İhbar oluşturabilmek için kayıt olup sayfanıza giriş yapmalısınız..\n"
                  "2. İhbar haritasını ve listesini görmek için uygulamaya kayıt olmanıza gerek yoktur..\n"
                  "3. Yetkiliyseniz, kurtarılan kişilerin konumlarını ve durumlarını güncelleyebilirsiniz.\n"
                  "4. Haritada kırmızı ile gösterilen konumlar onaylanmış ihbarları, yeşil ile gösterilen konumlar kurtarılan kişileri göstermektedir.\n"
                  "5. Güncellenen konumlar herkes tarafından görülebilir.",
              style: TextStyle(fontSize: 18),
            ),

            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color:Colors.white, size:30,),
                    SizedBox(width: 20),
                    Text(
                      'Geri Dön',
                      style: TextStyle(
                        color: Colors.white, fontSize: 22,
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