import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'user_auth_service.dart';

import 'login.dart';
import 'signup.dart';
import 'map.dart';
import 'howuse.dart';
import 'edit_not.dart';
import 'ihbar_olusturma_sayfasi.dart';
import 'menu.dart';
import 'admin_ihbar_yonetim_sayfasi.dart';
import 'genel_onayli_ihbar_listesi_sayfasi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase başarıyla başlatıldı.");
  } catch (e) {
    print("Firebase başlatma hatası: $e");
  }
  try {
    await initializeDateFormatting('tr_TR', null);
    print("Tarih formatları (tr_TR) başarıyla yüklendi.");
  } catch (e) {
    print("Tarih formatları yüklenirken hata: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserAuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deprem İhbar Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFDC321E),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDC321E)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFDC321E),
          foregroundColor: Colors.white,
          elevation: 4.0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC321E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const GirisSayfasi(),
        '/signup': (context) => const KayitSayfasi(),
        '/normal_kullanici_anasayfa':(context) => const NormalKullaniciAnaSayfasi(),
        '/admin_anasayfa':(context) => const AdminAnaSayfasi(),
        '/map': (context) => const HaritaSayfasi(),
        '/ihbarlarim': (context) => const IhbarDuzenleSayfasi(),
        '/yeni-ihbar': (context) => const IhbarOlusturmaSayfasi(),
        '/nasil-kullanilir': (context) => const NasilKullanilir(),
        AdminIhbarYonetimSayfasi.routeName: (context) => const AdminIhbarYonetimSayfasi(),
        GenelOnayliIhbarListesiSayfasi.routeName: (context) => const GenelOnayliIhbarListesiSayfasi(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userAuthService = Provider.of<UserAuthService>(context);

    if (userAuthService.isLoggedIn && userAuthService.currentUser != null) {
      print("Giriş yapan kullanıcı: ${userAuthService.currentUser!.email}, Rol: ${userAuthService.currentUser!.role}");
      if (userAuthService.isAdmin) {
        return const AdminAnaSayfasi();
      } else {
        return const NormalKullaniciAnaSayfasi();
      }
    } else {
      return const GirisSayfasi();
    }
  }
}

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

// --- ADMIN ANA SAYFASI ---
class AdminAnaSayfasi extends StatelessWidget {
  const AdminAnaSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final userAuthService = Provider.of<UserAuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        automaticallyImplyLeading: false,
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
              'Admin Paneline Hoş Geldiniz, ${userAuthService.currentUser?.displayName ?? userAuthService.currentUser?.email ?? 'Admin'}!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
              label: const Text('Yeni İhbar Oluştur (Admin)', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pushNamed(context, '/yeni-ihbar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt_outlined, color: Colors.white),
              label: const Text('Oluşturduğum İhbarlar (Admin)', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pushNamed(context, '/ihbarlarim'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700], padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
              label: const Text('Tüm İhbarları Yönet/Onayla', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pushNamed(context, AdminIhbarYonetimSayfasi.routeName),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
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
