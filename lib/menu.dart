import 'package:flutter/material.dart';

class MenuSayfasi extends StatelessWidget {
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
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Menü',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24, // Yazı boyutunu da ayarlayabilirsiniz
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.white, size: 40),
                  onPressed: () {
                    Navigator.pop(context); // Çekmeceyi kapat
                  },
                ),
              ],
            ),
          ),
          // MENÜ ÖGELERİNİ BURAYA EKLEYECEĞİM
        ],
      ),
    );
  }
}
