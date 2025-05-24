import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'login.dart'; // Giriş sayfasına yönlendirme için
// import '../main.dart'; // AnaSayfa'ya yönlendirme için (veya hangi sayfaysa)


class KayitSayfasi extends StatefulWidget {
  const KayitSayfasi({super.key});

  @override
  State<KayitSayfasi> createState() => _KayitSayfasiState();
}

class _KayitSayfasiState extends State<KayitSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController(); // İsteğe bağlı: Kullanıcı adı
  bool _isLoading = false;

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Kullanıcı adını güncelle (isteğe bağlı)
        if (_displayNameController.text.trim().isNotEmpty) {
          await user.updateDisplayName(_displayNameController.text.trim());
        }

        // Firestore'a kullanıcı bilgilerini ve rolünü kaydet
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': _displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : user.email, // Eğer display name girilmemişse email'i kullan
          'role': 'user', // Varsayılan rol: user
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
          );
          // Kayıt sonrası giriş sayfasına veya doğrudan ana sayfaya yönlendir
          Navigator.of(context).popUntil((route) => route.isFirst); // Tüm sayfaları kapatıp ana sayfaya döner
          // Veya sadece bir önceki sayfaya dön: Navigator.of(context).pop();
          // Veya giriş sayfasına yönlendir:
          // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginSayfasi()));
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Kayıt hatası: ${e.code} - ${e.message}");
      String errorMessage = "Kayıt sırasında bir hata oluştu.";
      if (e.code == 'weak-password') {
        errorMessage = 'Şifre çok zayıf.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Bu e-posta adresi zaten kayıtlı.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Geçersiz e-posta adresi.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      print("Beklenmedik kayıt hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Beklenmedik bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Yeni Hesap Oluştur',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad (Opsiyonel)',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-posta Adresi',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-posta boş bırakılamaz.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Geçerli bir e-posta adresi girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre boş bırakılamaz.';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _kayitOl,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Kayıt Ol'),
                ),
                TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Giriş sayfasına geri dön
                    } else {
                      // Eğer pop yapacak sayfa yoksa, login sayfasına push et (ana sayfada değilsek)
                      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginSayfasi()));
                    }
                  },
                  child: Text(
                    'Zaten bir hesabınız var mı? Giriş Yapın',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
    