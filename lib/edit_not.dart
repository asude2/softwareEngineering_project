import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'ihbar_olusturma_sayfasi.dart'; // Yeni ihbar oluşturma sayfası

class IhbarDuzenleSayfasi extends StatefulWidget {
  const IhbarDuzenleSayfasi({super.key});

  @override
  State<IhbarDuzenleSayfasi> createState() => _IhbarDuzenleSayfasiState();
}

class _IhbarDuzenleSayfasiState extends State<IhbarDuzenleSayfasi> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _silIhbar(String docId) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: const Text(
            'Bu ihbar kalıcı olarak silinecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Evet, Sil', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('ihbarlar')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('İhbar başarıyla silindi.')));
        }
      } catch (e) {
        print("İhbar silme hatası: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('İhbar silinirken bir hata oluştu: $e')));
        }
      }
    }
  }

  void _duzenleIhbar(
      BuildContext context, String docId, Map<String, dynamic> currentData) {
    final adSoyadController =
    TextEditingController(text: currentData['ihbar_edilen_ad_soyad'] as String? ?? '');
    final tcController =
    TextEditingController(text: currentData['tc'] as String? ?? '');
    final telefonController =
    TextEditingController(text: currentData['telefon'] as String? ?? '');
    final ilController =
    TextEditingController(text: currentData['il'] as String? ?? '');
    final ilceController =
    TextEditingController(text: currentData['ilce'] as String? ?? '');
    final adresController =
    TextEditingController(text: currentData['detayli_adres'] as String? ?? '');
    final aciklamaController =
    TextEditingController(text: currentData['aciklama'] as String? ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İhbarı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: adSoyadController, decoration: const InputDecoration(labelText: 'Ad Soyad')),
              const SizedBox(height: 8),
              TextField(controller: tcController, decoration: const InputDecoration(labelText: 'TC (Opsiyonel)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: telefonController, decoration: const InputDecoration(labelText: 'Telefon (Opsiyonel)'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: ilController, decoration: const InputDecoration(labelText: 'İl')),
              const SizedBox(height: 8),
              TextField(controller: ilceController, decoration: const InputDecoration(labelText: 'İlçe')),
              const SizedBox(height: 8),
              TextField(controller: adresController, decoration: const InputDecoration(labelText: 'Detaylı Adres'), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: aciklamaController, decoration: const InputDecoration(labelText: 'Kısa Açıklama (Harita için)'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!mounted) return;
              try {
                String yeniAciklama = aciklamaController.text.trim().isNotEmpty
                    ? aciklamaController.text.trim()
                    : '${ilController.text.trim()}, ${ilceController.text.trim()} - ${adresController.text.trim()}';

                if (yeniAciklama.length > 150) {
                  yeniAciklama = "${yeniAciklama.substring(0,147)}...";
                }

                Map<String, dynamic> guncellenecekVeri = {
                  'ihbar_edilen_ad_soyad': adSoyadController.text.trim(),
                  'tc': tcController.text.trim(),
                  'telefon': telefonController.text.trim(),
                  'il': ilController.text.trim(),
                  'ilce': ilceController.text.trim(),
                  'detayli_adres': adresController.text.trim(),
                  'aciklama': yeniAciklama,
                  'tarih': FieldValue.serverTimestamp(),
                };

                if (currentData.containsKey('konum') && currentData['konum'] is GeoPoint) {
                  guncellenecekVeri['konum'] = currentData['konum'];
                }
                if (currentData.containsKey('onaylandiMi')) { // Onay durumunu koru
                  guncellenecekVeri['onaylandiMi'] = currentData['onaylandiMi'];
                }
                if (currentData.containsKey('onaylayanAdminUid')) {
                  guncellenecekVeri['onaylayanAdminUid'] = currentData['onaylayanAdminUid'];
                }
                if (currentData.containsKey('onayTarihi')) {
                  guncellenecekVeri['onayTarihi'] = currentData['onayTarihi'];
                }


                await FirebaseFirestore.instance
                    .collection('ihbarlar')
                    .doc(docId)
                    .update(guncellenecekVeri);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('İhbar başarıyla güncellendi.')));
                }
              } catch (e) {
                print("İhbar güncelleme hatası: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('İhbar güncellenirken bir hata oluştu: $e')));
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("İhbarlarım"),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "İhbarlarınızı görmek için lütfen giriş yapın.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Oluşturduğum İhbarlar"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ihbarlar')
            .where('ihbar_eden_uid', isEqualTo: user!.uid)
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Firestore stream hatası (İhbarlarım): ${snapshot.error}");
            return Center(
                child: Text(
                    "İhbarlar yüklenirken bir hata oluştu. Lütfen daha sonra tekrar deneyin. Hata: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Henüz oluşturulmuş bir ihbarınız bulunmamaktadır.\nSağ alttaki '+' butonu ile yeni ihbar ekleyebilirsiniz.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              String formattedDate = "Tarih bilgisi yok";
              if (data.containsKey('tarih') && data['tarih'] != null && data['tarih'] is Timestamp) {
                DateTime date = (data['tarih'] as Timestamp).toDate();
                try {
                  formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date);
                } catch (e) {
                  print("Tarih formatlama hatası (İhbarlarım): $e");
                  formattedDate = "${date.day}/${date.month}/${date.year}";
                }
              }

              String konumText = 'Konum bilgisi kaydedilmemiş.';
              Color konumRenk = Colors.orange[800]!;
              FontStyle konumFontStyle = FontStyle.italic;

              if (data.containsKey('konum') && data['konum'] != null && data['konum'] is GeoPoint) {
                GeoPoint geoPoint = data['konum'] as GeoPoint;
                konumText = 'Konum: ${geoPoint.latitude.toStringAsFixed(4)}, ${geoPoint.longitude.toStringAsFixed(4)}';
                konumRenk = Colors.blueGrey[700]!;
                konumFontStyle = FontStyle.normal;
              }

              bool onayDurumu = data.containsKey('onaylandiMi') ? (data['onaylandiMi'] as bool? ?? false) : false;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  leading: Icon(
                    onayDurumu ? Icons.check_circle_outline : Icons.hourglass_empty_outlined,
                    color: onayDurumu ? Colors.green.shade700 : Colors.orange.shade700,
                    size: 30,
                  ),
                  title: Text(data['ihbar_edilen_ad_soyad'] as String? ?? 'Ad Soyad Yok',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Adres: ${data['detayli_adres'] as String? ?? 'Belirtilmemiş'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('Açıklama: ${data['aciklama'] as String? ?? 'Yok'}', style: TextStyle(fontSize: 13, color: Colors.grey[800]), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Text(
                            konumText,
                            style: TextStyle(fontSize: 12, color: konumRenk, fontStyle: konumFontStyle),
                          ),
                        ),
                        Text(
                          onayDurumu ? 'Durum: Onaylandı' : 'Durum: Onay Bekliyor',
                          style: TextStyle(fontSize: 12, color: onayDurumu ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note_outlined, color: Colors.blueAccent),
                        tooltip: 'Düzenle',
                        onPressed: () => _duzenleIhbar(context, doc.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                        tooltip: 'Sil',
                        onPressed: () => _silIhbar(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IhbarOlusturmaSayfasi()),
          );
        },
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text("Yeni İhbar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4.0,
      ),
    );
  }
}
