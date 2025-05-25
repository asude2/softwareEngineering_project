import 'package:depsis_project/menu.dart';
import 'package:depsis_project/profilePage.dart';
import 'package:flutter/material.dart';
import 'user_auth_service.dart';
import 'package:provider/provider.dart';

// --- NORMAL KULLANICI ANA SAYFASI ---
class NormalKullaniciAnaSayfasi extends StatelessWidget {
  const NormalKullaniciAnaSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final userAuthService = Provider.of<UserAuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        automaticallyImplyLeading: false, // Geri butonunu kaldırır, menü ile açılır
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Oturumu sonlandırmak istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hayır')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Evet, Çıkış Yap', style: TextStyle(color: Colors.white))),
                  ],
                ),
              );
              if (confirm == true) {
                await userAuthService.signOut();
              }
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              tooltip: 'Menü',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const MenuSayfasi(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hoş Geldiniz, ${userAuthService.currentUser?.displayName ?? userAuthService.currentUser?.email ?? 'Kullanıcı'}!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
              label: const Text('Yeni İhbar Oluştur', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pushNamed(context, '/yeni-ihbar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt_outlined, color: Colors.white),
              label: const Text('Oluşturduğum İhbarlar', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pushNamed(context, '/ihbarlarim'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700], padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.map_outlined, color: Colors.white),
              label: const Text("Onaylı İhbar Haritası", style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pushNamed(context, '/map'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}