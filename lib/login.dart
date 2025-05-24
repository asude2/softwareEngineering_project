import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Diğer sayfa importları
import 'signup.dart';
import 'genel_onayli_ihbar_listesi_sayfasi.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        // AuthWrapper zaten yönlendirecek
      }
    } on FirebaseAuthException catch (e) {
      print("Giriş hatası: ${e.code} - ${e.message}");
      String friendlyMessage = "Giriş sırasında bir hata oluştu.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        friendlyMessage = 'E-posta veya şifre hatalı.';
      } else if (e.code == 'invalid-email') {
        friendlyMessage = 'Geçersiz e-posta adresi.';
      } else if (e.code == 'user-disabled') {
        friendlyMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      }
      if (mounted) {
        setState(() {
          _errorMessage = friendlyMessage;
        });
      }
    } catch (e) {
      print("Beklenmedik giriş hatası: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Beklenmedik bir hata oluştu. Lütfen tekrar deneyin.";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildAuthButton(BuildContext context, String label, VoidCallback onPressed, {Color? backgroundColor, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: icon != null ? Icon(icon, color: Colors.white) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Image.asset(
                  'assets/8.png',
                  height: MediaQuery.of(context).size.height * 0.2,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'Deprem İhbar Sistemine Hoş Geldiniz',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                          if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value.trim())) {
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
                          return null;
                        },
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildAuthButton(context, 'Giriş Yap', _girisYap, icon: Icons.login),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildAuthButton(
                    context,
                    'Kayıt Ol',
                        () => Navigator.pushNamed(context, '/signup'),
                    backgroundColor: Colors.blueGrey[700],
                    icon: Icons.person_add_alt_1_outlined
                ),
                const SizedBox(height: 24),
                const Divider(thickness: 1),
                const SizedBox(height: 12),
                Text(
                  'Genel Bilgiler:',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                // "Hızlı İhbar Oluştur" butonu kaldırıldı.
                _buildAuthButton(
                    context,
                    'Onaylı İhbarlar (Liste)',
                        () => Navigator.pushNamed(context, GenelOnayliIhbarListesiSayfasi.routeName),
                    backgroundColor: Colors.teal[700],
                    icon: Icons.playlist_add_check_outlined
                ),
                _buildAuthButton(
                    context,
                    'Onaylı İhbar Haritası',
                        () => Navigator.pushNamed(context, '/map'),
                    backgroundColor: Colors.indigo[700],
                    icon: Icons.map_outlined
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
