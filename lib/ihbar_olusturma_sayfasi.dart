import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Position, getCurrentPosition, checkPermission vs.
import 'package:geocoding/geocoding.dart';   // locationFromAddress



class IhbarOlusturmaSayfasi extends StatefulWidget {
  const IhbarOlusturmaSayfasi({super.key});

  @override
  State<IhbarOlusturmaSayfasi> createState() => _IhbarOlusturmaSayfasiState();
}

class _IhbarOlusturmaSayfasiState extends State<IhbarOlusturmaSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _tcController = TextEditingController();
  final _telefonController = TextEditingController();
  final _ilController = TextEditingController();
  final _ilceController = TextEditingController();
  final _detayliAdresController = TextEditingController();
  final _aciklamaController = TextEditingController();

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isGeocoding = false;
  bool _isSaving = false;

  Future<void> _getCurrentLocationByGPS() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Konum izni reddedildi. Lütfen ayarlardan izin verin.')));
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Konum izni kalıcı olarak reddedildi. Ayarlardan değiştirin.')));
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mevcut GPS konumu başarıyla alındı!')));
      }
    } catch (e) {
      print("GPS Konum alma hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GPS konumu alınırken hata oluştu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getCoordinatesFromAddress() async {
    if (_ilController.text.trim().isEmpty ||
        _ilceController.text.trim().isEmpty ||
        _detayliAdresController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
          Text('Lütfen İl, İlçe ve Detaylı Adres alanlarını doldurun.')));
      return;
    }
    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      String fullAddress =
          '${_detayliAdresController.text.trim()}, ${_ilceController.text.trim()}, ${_ilController.text.trim()}, Türkiye';

      List<Location> locations = await locationFromAddress(fullAddress);

      if (locations.isNotEmpty) {
        final firstLocation = locations.first;
        _currentPosition = Position(
          latitude: firstLocation.latitude,
          longitude: firstLocation.longitude,
          timestamp: firstLocation.timestamp,
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Adresten konum bulundu: $fullAddress')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu adres için konum bulunamadı.')));
        }
      }
    } catch (e) {
      print("Geocoding hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Adresten konum bulunurken hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _kaydetIhbar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir konum belirleyin (GPS veya Adresten).')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('İhbar oluşturmak için giriş yapmalısınız.')));
      // İsteğe bağlı: Kullanıcıyı giriş sayfasına yönlendir
      // Navigator.pushNamed(context, '/login');
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      String aciklama = _aciklamaController.text.trim().isNotEmpty
          ? _aciklamaController.text.trim()
          : '${_ilController.text.trim()}, ${_ilceController.text.trim()} - ${_detayliAdresController.text.trim()}';

      if (aciklama.length > 150) {
        aciklama = "${aciklama.substring(0,147)}...";
      }

      await FirebaseFirestore.instance.collection('ihbarlar').add({
        'ihbar_eden_uid': user.uid,
        'ihbar_edilen_ad_soyad': _adSoyadController.text.trim(),
        'tc': _tcController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'il': _ilController.text.trim(),
        'ilce': _ilceController.text.trim(),
        'detayli_adres': _detayliAdresController.text.trim(),
        'aciklama': aciklama,
        'konum': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        'tarih': FieldValue.serverTimestamp(),
        'onaylandiMi': false,
        'kurtarildiMi': false, // YENİ EKLENDİ: Varsayılan kurtarılma durumu
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İhbar başarıyla oluşturuldu ve admin onayı bekleniyor.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("İhbar kaydetme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İhbar kaydedilirken hata oluştu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _adSoyadController.dispose();
    _tcController.dispose();
    _telefonController.dispose();
    _ilController.dispose();
    _ilceController.dispose();
    _detayliAdresController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool isRequired = false,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText + (isRequired ? " *" : ""),
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) =>
        value == null || value.trim().isEmpty ? 'Bu alan boş bırakılamaz' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı giriş yapmamışsa, bu sayfaya erişimi engelleyebiliriz veya uyarı gösterebiliriz.
    // Ancak şu anki akışta AuthWrapper'dan sonra geliyorsa bu sorun olmaz.
    // Eğer /yeni-ihbar rotası giriş yapmadan da erişilebilirse, burada bir kontrol gerekebilir.
     final user = FirebaseAuth.instance.currentUser;
     if (user == null && ModalRoute.of(context)?.settings.name == '/yeni-ihbar') {
    //   Örneğin, giriş sayfasına yönlendir
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return Scaffold(body: Center(child: Text("Bu sayfayı görmek için giriş yapmalısınız.")));
     }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İhbar Oluştur'),
        backgroundColor: const Color(0xFFDC321E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextFormField(
                controller: _adSoyadController,
                labelText: 'İhbar Edilen Ad Soyad',
                isRequired: true,
                prefixIcon: Icons.person_outline,
              ),
              _buildTextFormField(
                controller: _tcController,
                labelText: 'TC Kimlik No',
                hintText: 'Opsiyonel',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
              ),
              _buildTextFormField(
                controller: _telefonController,
                labelText: 'Telefon Numarası',
                hintText: 'Opsiyonel',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              _buildTextFormField(
                controller: _ilController,
                labelText: 'İl',
                isRequired: true,
                prefixIcon: Icons.location_city_outlined,
              ),
              _buildTextFormField(
                controller: _ilceController,
                labelText: 'İlçe',
                isRequired: true,
                prefixIcon: Icons.holiday_village_outlined,
              ),
              _buildTextFormField(
                controller: _detayliAdresController,
                labelText: 'Detaylı Adres',
                hintText: 'Mahalle, cadde, sokak, bina no vb.',
                isRequired: true,
                maxLines: 3,
                prefixIcon: Icons.home_work_outlined,
              ),
              _buildTextFormField(
                controller: _aciklamaController,
                labelText: 'Kısa Açıklama (Harita için)',
                hintText: 'Durum hakkında kısa bilgi',
                isRequired: true,
                maxLines: 2,
                prefixIcon: Icons.info_outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Konum Belirleme:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _isLoadingLocation
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Mevcut GPS Konumumu Al'),
                onPressed: _getCurrentLocationByGPS,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
              const SizedBox(height: 10),
              _isGeocoding
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.location_searching),
                label: const Text('Girdiğim Adresten Konum Bul'),
                onPressed: _getCoordinatesFromAddress,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                      'Seçilen Konum: Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('İhbarı Gönder', style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: _kaydetIhbar,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC321E),
                    padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
