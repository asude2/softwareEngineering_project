import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_auth_service.dart';

class AdminIhbarYonetimSayfasi extends StatefulWidget {
  const AdminIhbarYonetimSayfasi({super.key});

  static const String routeName = '/admin-ihbar-yonetim';

  @override
  State<AdminIhbarYonetimSayfasi> createState() => _AdminIhbarYonetimSayfasiState();
}

class _AdminIhbarYonetimSayfasiState extends State<AdminIhbarYonetimSayfasi> {
  String _filterOption = 'Tümü'; // Tümü, Onay Bekleyen, Onaylanmış, Kurtarılmayı Bekleyen, Kurtarılmış

  Future<void> _updateIhbarStatus(String docId, {bool? onaylandiMi, bool? kurtarildiMi, String? adminUid}) async {
    if (!mounted) return;
    Map<String, dynamic> dataToUpdate = {};
    String successMessage = "İhbar durumu güncellendi.";

    if (onaylandiMi != null) {
      dataToUpdate['onaylandiMi'] = onaylandiMi;
      if (onaylandiMi == true) {
        dataToUpdate['onaylayanAdminUid'] = adminUid;
        dataToUpdate['onayTarihi'] = FieldValue.serverTimestamp();
        successMessage = "İhbar başarıyla onaylandı.";
      } else { // Onay kaldırılıyorsa
        dataToUpdate['onaylayanAdminUid'] = FieldValue.delete();
        dataToUpdate['onayTarihi'] = FieldValue.delete();
        dataToUpdate['kurtarildiMi'] = false; // Onay kalkarsa kurtarılma durumu da sıfırlanır
        dataToUpdate['kurtaranAdminUid'] = FieldValue.delete();
        dataToUpdate['kurtarilmaTarihi'] = FieldValue.delete();
        successMessage = "İhbar onayı kaldırıldı.";
      }
    }

    if (kurtarildiMi != null) {
      dataToUpdate['kurtarildiMi'] = kurtarildiMi;
      if (kurtarildiMi == true) {
        dataToUpdate['kurtaranAdminUid'] = adminUid; // Kurtaran admin
        dataToUpdate['kurtarilmaTarihi'] = FieldValue.serverTimestamp();
        successMessage = "İhbar 'Kurtarıldı' olarak işaretlendi.";
      } else { // Kurtarıldı durumu kaldırılıyorsa
        dataToUpdate['kurtaranAdminUid'] = FieldValue.delete();
        dataToUpdate['kurtarilmaTarihi'] = FieldValue.delete();
        successMessage = "'Kurtarıldı' durumu kaldırıldı.";
      }
    }

    if (dataToUpdate.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('ihbarlar').doc(docId).update(dataToUpdate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      print("İhbar durum güncelleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İhbar durumu güncellenirken bir hata oluştu: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final userAuthService = Provider.of<UserAuthService>(context, listen: false);
    final adminUid = userAuthService.currentUser?.uid;

    if (adminUid == null || !userAuthService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetkisiz Erişim')),
        body: const Center(child: Text('Bu sayfayı görüntüleme yetkiniz yok.')),
      );
    }

    Query query = FirebaseFirestore.instance.collection('ihbarlar').orderBy('tarih', descending: true);

    // Filtreleme mantığı güncellendi
    if (_filterOption == 'Onay Bekleyen') {
      query = query.where('onaylandiMi', isEqualTo: false);
    } else if (_filterOption == 'Onaylanmış (Kurtarılmadı)') {
      query = query.where('onaylandiMi', isEqualTo: true).where('kurtarildiMi', isEqualTo: false);
    } else if (_filterOption == 'Kurtarılmış') {
      query = query.where('kurtarildiMi', isEqualTo: true);
    } else if (_filterOption == 'Tüm Onaylanmışlar') {
      query = query.where('onaylandiMi', isEqualTo: true);
    }
    // 'Tümü' seçeneği için ek bir .where koşuluna gerek yok, tüm ihbarları getirir.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - İhbar Yönetimi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filtrele",
            onSelected: (String value) {
              setState(() {
                _filterOption = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'Tümü', child: Text('Tüm İhbarlar')),
              const PopupMenuItem<String>(value: 'Onay Bekleyen', child: Text('Onay Bekleyenler')),
              const PopupMenuItem<String>(value: 'Onaylanmış (Kurtarılmadı)', child: Text('Onaylı (Kurtarılmadı)')),
              const PopupMenuItem<String>(value: 'Kurtarılmış', child: Text('Kurtarılmış Olanlar')),
              const PopupMenuItem<String>(value: 'Tüm Onaylanmışlar', child: Text('Tüm Onaylanmışlar')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Filtreye uygun ihbar bulunamadı: $_filterOption'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              bool onaylandi = data.containsKey('onaylandiMi') ? data['onaylandiMi'] as bool : false;
              bool kurtarildi = data.containsKey('kurtarildiMi') ? data['kurtarildiMi'] as bool : false;

              String formattedDate = "Tarih yok";
              if (data.containsKey('tarih') && data['tarih'] is Timestamp) {
                try {
                  formattedDate = DateFormat('dd.MM.yy HH:mm', 'tr_TR').format((data['tarih'] as Timestamp).toDate());
                } catch(e) { /* Hata olursa varsayılan format */ }
              }

              String durumText = "Bilinmiyor";
              Color durumRenk = Colors.grey;
              IconData durumIkon = Icons.help_outline;

              if (kurtarildi) {
                durumText = "Kurtarıldı";
                durumRenk = Colors.green.shade700;
                durumIkon = Icons.task_alt;
              } else if (onaylandi) {
                durumText = "Onaylandı (Kurtarılmayı Bekliyor)";
                durumRenk = Colors.blue.shade700;
                durumIkon = Icons.check_circle_outline;
              } else {
                durumText = "Onay Bekliyor";
                durumRenk = Colors.orange.shade800;
                durumIkon = Icons.hourglass_empty_outlined;
              }


              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: Icon(durumIkon, color: durumRenk, size: 30),
                  title: Text(data['ihbar_edilen_ad_soyad'] as String? ?? 'İsimsiz İhbar', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Açıklama: ${data['aciklama'] as String? ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Adres: ${data['detayli_adres'] as String? ?? '-'} (${data['ilce'] as String? ?? ''}/${data['il'] as String? ?? ''})', maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (data.containsKey('konum') && data['konum'] is GeoPoint)
                        Text('Konum: ${(data['konum'] as GeoPoint).latitude.toStringAsFixed(3)}, ${(data['konum'] as GeoPoint).longitude.toStringAsFixed(3)}'),
                      Text('Tarih: $formattedDate'),
                      Text('Durum: $durumText', style: TextStyle(fontWeight: FontWeight.bold, color: durumRenk)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!onaylandi)
                        ElevatedButton(
                          child: const Text('Onayla'),
                          onPressed: () => _updateIhbarStatus(doc.id, onaylandiMi: true, adminUid: adminUid),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        )
                      else if (onaylandi && !kurtarildi) ...[
                        ElevatedButton(
                          child: const Text('Kurtarıldı'),
                          onPressed: () => _updateIhbarStatus(doc.id, kurtarildiMi: true, adminUid: adminUid),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        ),
                        TextButton(
                          child: const Text('Onayı Kaldır', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
                          onPressed: () => _updateIhbarStatus(doc.id, onaylandiMi: false, adminUid: adminUid),
                        )
                      ]
                      else if (onaylandi && kurtarildi) ...[
                          TextButton(
                            child: const Text('Kurtarıldı İptal', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                            onPressed: () => _updateIhbarStatus(doc.id, kurtarildiMi: false, adminUid: adminUid),
                          ),
                          TextButton(
                            child: const Text('Onayı Kaldır', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
                            onPressed: () => _updateIhbarStatus(doc.id, onaylandiMi: false, adminUid: adminUid),
                          )
                        ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
