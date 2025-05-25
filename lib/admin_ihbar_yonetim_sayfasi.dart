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
  String _filterOption = 'Tümü';

  Future<void> _deleteIhbar(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('ihbarlar').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İhbar başarıyla silindi.')),
        );
      }
    } catch (e) {
      debugPrint('İhbar silme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İhbar silinirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: const Text('Bu ihbarı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteIhbar(docId);
    }
  }


  // İhbar durumu güncelleme fonksiyonu
  Future<void> _updateIhbarStatus(
      String docId, {
        bool? onaylandiMi,
        bool? kurtarildiMi,
        String? adminUid,
      }) async {
    if (!mounted) return;

    Map<String, dynamic> dataToUpdate = {};
    String successMessage = "İhbar durumu güncellendi.";

    if (onaylandiMi != null) {
      dataToUpdate['onaylandiMi'] = onaylandiMi;
      if (onaylandiMi) {
        dataToUpdate['onaylayanAdminUid'] = adminUid;
        dataToUpdate['onayTarihi'] = FieldValue.serverTimestamp();
        successMessage = "İhbar başarıyla onaylandı.";
      } else {
        // Onay kaldırılırsa diğer ilgili alanları temizle
        dataToUpdate.addAll({
          'onaylayanAdminUid': FieldValue.delete(),
          'onayTarihi': FieldValue.delete(),
          'kurtarildiMi': false,
          'kurtaranAdminUid': FieldValue.delete(),
          'kurtarilmaTarihi': FieldValue.delete(),
        });
        successMessage = "İhbar onayı kaldırıldı.";
      }
    }

    if (kurtarildiMi != null) {
      dataToUpdate['kurtarildiMi'] = kurtarildiMi;
      if (kurtarildiMi) {
        dataToUpdate['kurtaranAdminUid'] = adminUid;
        dataToUpdate['kurtarilmaTarihi'] = FieldValue.serverTimestamp();
        successMessage = "İhbar 'Kurtarıldı' olarak işaretlendi.";
      } else {
        dataToUpdate.addAll({
          'kurtaranAdminUid': FieldValue.delete(),
          'kurtarilmaTarihi': FieldValue.delete(),
        });
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
      debugPrint("İhbar durum güncelleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İhbar durumu güncellenirken bir hata oluştu: $e')),
        );
      }
    }
  }

  Query _getFilteredQuery() {
    Query baseQuery = FirebaseFirestore.instance.collection('ihbarlar').orderBy('tarih', descending: true);

    switch (_filterOption) {
      case 'Onay Bekleyen':
        return baseQuery.where('onaylandiMi', isEqualTo: false);
      case 'Onaylanmış (Kurtarılmadı)':
        return baseQuery.where('onaylandiMi', isEqualTo: true).where('kurtarildiMi', isEqualTo: false);
      case 'Kurtarılmış':
        return baseQuery.where('kurtarildiMi', isEqualTo: true);
      case 'Tüm Onaylanmışlar':
        return baseQuery.where('onaylandiMi', isEqualTo: true);
      case 'Tümü':
      default:
        return baseQuery;
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

    final query = _getFilteredQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - İhbar Yönetimi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filtrele",
            onSelected: (value) => setState(() => _filterOption = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Tümü', child: Text('Tüm İhbarlar')),
              PopupMenuItem(value: 'Onay Bekleyen', child: Text('Onay Bekleyenler')),
              PopupMenuItem(value: 'Onaylanmış (Kurtarılmadı)', child: Text('Onaylı (Kurtarılmadı)')),
              PopupMenuItem(value: 'Kurtarılmış', child: Text('Kurtarılmış Olanlar')),
              PopupMenuItem(value: 'Tüm Onaylanmışlar', child: Text('Tüm Onaylanmışlar')),
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

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Text('Filtreye uygun ihbar bulunamadı: $_filterOption'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final bool onaylandi = data['onaylandiMi'] ?? false;
              final bool kurtarildi = data['kurtarildiMi'] ?? false;

              // Tarih formatlama
              String formattedDate = "Tarih yok";
              final tarih = data['tarih'];
              if (tarih is Timestamp) {
                try {
                  formattedDate = DateFormat('dd.MM.yy HH:mm', 'tr_TR').format(tarih.toDate());
                } catch (_) {}
              }

              // Durum bilgileri
              String durumText;
              Color durumRenk;
              IconData durumIkon;

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
                  title: Text(
                    data['ihbar_edilen_ad_soyad'] ?? 'İsimsiz İhbar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Açıklama: ${data['aciklama'] ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        'Adres: ${data['detayli_adres'] ?? '-'} (${data['ilce'] ?? ''}/${data['il'] ?? ''})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (data['konum'] is GeoPoint)
                        Text(
                          'Konum: ${(data['konum'] as GeoPoint).latitude.toStringAsFixed(3)}, ${(data['konum'] as GeoPoint).longitude.toStringAsFixed(3)}',
                        ),
                      Text('Tarih: $formattedDate'),
                      Text('Durum: $durumText', style: TextStyle(fontWeight: FontWeight.bold, color: durumRenk)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButtons(doc.id, onaylandi, kurtarildi, adminUid),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'İhbarı Sil',
                        onPressed: () => _confirmDelete(doc.id),
                      ),
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

  // İşlemler için butonlar
  Widget _buildActionButtons(String docId, bool onaylandi, bool kurtarildi, String? adminUid) {
    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      foregroundColor: Colors.white,
    );

    if (!onaylandi) {
      return ElevatedButton(
        onPressed: () => _updateIhbarStatus(docId, onaylandiMi: true, adminUid: adminUid),
        style: buttonStyle.copyWith(backgroundColor: MaterialStateProperty.all(Colors.green)),
        child: const Text('Onayla'),
      );
    } else if (onaylandi && !kurtarildi) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _updateIhbarStatus(docId, kurtarildiMi: true, adminUid: adminUid),
            style: buttonStyle.copyWith(backgroundColor: MaterialStateProperty.all(Colors.blueAccent)),
            child: const Text('Kurtarıldı'),
          ),
          TextButton(
            onPressed: () => _updateIhbarStatus(docId, onaylandiMi: false, adminUid: adminUid),
            child: const Text('Onayı Kaldır', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
          ),
        ],
      );
    } else if (onaylandi && kurtarildi) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _updateIhbarStatus(docId, kurtarildiMi: false, adminUid: adminUid),
            child: const Text('Kurtarıldı İptal', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
          ),
          TextButton(
            onPressed: () => _updateIhbarStatus(docId, onaylandiMi: false, adminUid: adminUid),
            child: const Text('Onayı Kaldır', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
          ),
        ],
      );
    }

    // Herhangi bir koşul sağlanmazsa boş widget döner
    return const SizedBox.shrink();
  }
}
