import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'user_auth_service.dart';
import 'login.dart';
import 'signup.dart';
import 'package:depsis_project/NormalPersonPage.dart';
import 'package:depsis_project/AdminPage.dart';
import 'map.dart';
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




