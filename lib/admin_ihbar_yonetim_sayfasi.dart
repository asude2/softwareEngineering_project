import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_auth_service.dart';

class AdminIhbarYonetimSayfasi extends StatefulWidget {
  const AdminIhbarYonetimSayfasi({super.key});
  static const String routeName = '/admin-ihbar-yonetim';

  @override
  State<AdminIhbarYonetimSayfasi> createState() =>
      _AdminIhbarYonetimSayfasiState();
}

class _AdminIhbarYonetimSayfasiState
    extends State<AdminIhbarYonetimSayfasi> {
  String _filterOption = 'Tümü'; // Varsayılan filtre

  Future<void> _deleteIhbar(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ihbarlar')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('İhbar başarıyla silindi.'),
              backgroundColor: Colors.green.shade700),
        );
      }
    } catch (e) {
      debugPrint('İhbar silme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('İhbar silinirken hata oluştu: $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(String docId, String ihbarAdi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text(
            "'$ihbarAdi' adlı ihbarı kalıcı olarak silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteIhbar(docId);
    }
  }

  Future<void> _updateIhbarStatus(
      String docId, {
        bool? onaylandiMi,
        bool? kurtarildiMi,
        required String? adminUid,
      }) async {
    if (!mounted || adminUid == null) {
      if (adminUid == null) {
        debugPrint("Admin UID null, güncelleme yapılamadı.");
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('İşlem için admin UID bulunamadı.'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
      return;
    }

    Map<String, dynamic> dataToUpdate = {};
    String successMessage = "İhbar durumu güncellendi.";

    if (onaylandiMi != null) {
      dataToUpdate['onaylandiMi'] = onaylandiMi;
      if (onaylandiMi) {
        dataToUpdate['onaylayanAdminUid'] = adminUid;
        dataToUpdate['onayTarihi'] = FieldValue.serverTimestamp();
        successMessage = "İhbar başarıyla onaylandı.";
      } else {
        // Onay kaldırılırsa, hem onay bilgileri hem de kurtarılma bilgileri silinir/resetlenir.
        dataToUpdate.addAll({
          'onaylayanAdminUid': FieldValue.delete(),
          'onayTarihi': FieldValue.delete(),
          'kurtarildiMi': false,
          'kurtaranAdminUid': FieldValue.delete(),
          'kurtarilmaTarihi': FieldValue.delete(),
        });
        successMessage = "İhbar onayı kaldırıldı. İlgili tüm durumlar sıfırlandı.";
      }
    }

    // kurtarildiMi durumu sadece onaylandiMi true ise anlamlıdır.
    // Eğer sadece kurtarildiMi durumu değiştiriliyorsa ve onaylandiMi null ise,
    // onaylandiMi'nin true olduğundan emin olmalıyız.
    if (kurtarildiMi != null) {
      if (onaylandiMi == null) { // Sadece kurtarılma durumu değişiyor
        dataToUpdate['onaylandiMi'] = true; // Kurtarılma varsa, onaylı olmalı
      }
      dataToUpdate['kurtarildiMi'] = kurtarildiMi;
      if (kurtarildiMi) {
        dataToUpdate['kurtaranAdminUid'] = adminUid;
        dataToUpdate['kurtarilmaTarihi'] = FieldValue.serverTimestamp();
        // Eğer onay bilgisi yoksa (örn. doğrudan kurtarıldı işaretlenirse) onu da ekle
        if (dataToUpdate['onaylayanAdminUid'] == null && dataToUpdate['onayTarihi'] == null) {
          dataToUpdate['onaylayanAdminUid'] = adminUid; // Onaylayan da aynı admin olsun
          dataToUpdate['onayTarihi'] = FieldValue.serverTimestamp(); // Onay tarihi de kurtarılma ile aynı olsun
        }
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
      await FirebaseFirestore.instance
          .collection('ihbarlar')
          .doc(docId)
          .update(dataToUpdate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: Colors.green.shade700));
      }
    } catch (e) {
      debugPrint("İhbar durum güncelleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('İhbar durumu güncellenirken bir hata oluştu: $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Query _getFilteredQuery() {
    Query baseQuery = FirebaseFirestore.instance
        .collection('ihbarlar')
        .orderBy('tarih', descending: true);

    // Firestore'da boolean alanlar için doğru sorgulama:
    // `isEqualTo: false` null olanları getirmez. Alanın var olup false olması gerekir.
    // `isEqualTo: null` da kullanılabilir ama alanın hiç olmaması durumunu da kapsamak için
    // ihbar oluştururken bu alanlara varsayılan değer (örn: false) atanması en iyisidir.

    switch (_filterOption) {
      case 'Onay Bekleyen':
      // En iyi pratik, ihbar oluştururken onaylandiMi: false olarak ayarlamaktır.
      // Eğer alan hiç yoksa bu sorgu onu getirmez.
        return baseQuery.where('onaylandiMi', isEqualTo: false);
      case 'Onaylanmış (Kurtarılmadı)':
        return baseQuery
            .where('onaylandiMi', isEqualTo: true)
            .where('kurtarildiMi', isEqualTo: false); // kurtarildiMi'nin false olduğu varsayılır
      case 'Kurtarılmış':
      // Kurtarılmışsa, onaylandiMi da true olmalıdır.
        return baseQuery
            .where('onaylandiMi', isEqualTo: true)
            .where('kurtarildiMi', isEqualTo: true);
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
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    if (adminUid == null || !userAuthService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yetkisiz Erişim')),
        body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Bu sayfayı görüntüleme yetkiniz bulunmamaktadır.',
                  textAlign: TextAlign.center, style: textTheme.titleLarge),
            )),
      );
    }

    final query = _getFilteredQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - İhbar Yönetimi'),
        actions: [
          Tooltip(
            message: "Filtrele: $_filterOption",
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list), // Düzeltilmiş ikon
              onSelected: (value) {
                if (_filterOption != value) {
                  setState(() => _filterOption = value);
                }
              },
              itemBuilder: (context) => [
                _buildFilterMenuItem('Tümü', context),
                _buildFilterMenuItem('Onay Bekleyen', context),
                _buildFilterMenuItem('Onaylanmış (Kurtarılmadı)', context),
                _buildFilterMenuItem('Kurtarılmış', context),
                _buildFilterMenuItem('Tüm Onaylanmışlar', context),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: colorScheme.primary));
          }

          if (snapshot.hasError) {
            debugPrint("Admin İhbar Yönetimi - Stream Hatası: ${snapshot.error}");
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'İhbarlar yüklenirken bir hata oluştu.\nDetay: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
                ));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      '$_filterOption filtresine uygun ihbar bulunamadı.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium
                          ?.copyWith(color: Colors.grey.shade600)),
                ));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0, bottom: 80.0), // Alt kısımda boşluk
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final bool onaylandi = data['onaylandiMi'] as bool? ?? false;
              final bool kurtarildi = data['kurtarildiMi'] as bool? ?? false;
              final String ihbarAdi = data['ihbar_edilen_ad_soyad'] as String? ?? 'İsimsiz İhbar';

              String formattedDate = "Tarih yok";
              final tarih = data['tarih'];
              if (tarih is Timestamp) {
                try {
                  formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(tarih.toDate());
                } catch (_) {
                  formattedDate = "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}";
                }
              }

              String durumText;
              Color durumRenk;
              IconData durumIkon;

              if (kurtarildi) {
                durumText = "Kurtarıldı";
                durumRenk = Colors.green.shade600;
                durumIkon = Icons.task_alt_rounded;
              } else if (onaylandi) {
                durumText = "Onaylandı (Yardım Bekliyor)";
                durumRenk = Colors.blue.shade700;
                durumIkon = Icons.check_circle_outline_rounded;
              } else {
                durumText = "Onay Bekliyor";
                durumRenk = Colors.orange.shade700;
                durumIkon = Icons.hourglass_empty_rounded;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                clipBehavior: Clip.antiAlias, // Köşelerin düzgün kesilmesi için
                child: InkWell( // Tüm karta tıklanabilirlik (opsiyonel)
                  onTap: () {
                    // İhbar detaylarını gösteren bir diyalog açılabilir.
                    // _showIhbarDetayDialog(context, data);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12), // Sağ padding'i 0 yaptık, PopupMenu için yer
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding( // İkon için padding
                          padding: const EdgeInsets.only(top: 4.0, right: 12.0),
                          child: Icon(durumIkon, color: durumRenk, size: 28),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ihbarAdi,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Açıklama: ${data['aciklama'] as String? ?? '-'}',
                                style: textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Adres: ${data['detayli_adres'] as String? ?? '-'} (${data['ilce'] as String? ?? ''} / ${data['il'] as String? ?? ''})',
                                style: textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (data.containsKey('konum') && data['konum'] is GeoPoint)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3.0),
                                  child: Text(
                                    'Konum: ${(data['konum'] as GeoPoint).latitude.toStringAsFixed(4)}, ${(data['konum'] as GeoPoint).longitude.toStringAsFixed(4)}',
                                    style: textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(right: 12), // Durum etiketine sağ boşluk
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: durumRenk.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      durumText,
                                      style: textTheme.labelSmall?.copyWith(color: durumRenk, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildActionPopupMenu(doc.id, onaylandi, kurtarildi, adminUid, ihbarAdi),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value, BuildContext context) {
    // `const` kaldırıldı, çünkü _filterOption ve Theme.of(context) const değil.
    return PopupMenuItem(
      value: value,
      child: Text(value, style: TextStyle(
        fontWeight: _filterOption == value ? FontWeight.bold : FontWeight.normal,
        color: _filterOption == value ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
      )),
    );
  }

  Widget _buildActionPopupMenu(String docId, bool onaylandi, bool kurtarildi, String? adminUid, String ihbarAdi) {
    // `const` kaldırıldı, çünkü içindeki widget'lar ve fonksiyon çağrıları const değil.
    List<PopupMenuEntry<String>> menuItems = [];

    if (!onaylandi) {
      menuItems.add(PopupMenuItem(value: 'onayla', child: Row(children: [Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700), const SizedBox(width: 8), const Text('Onayla')])));
    } else { // Onaylandıysa
      if (!kurtarildi) {
        menuItems.add(PopupMenuItem(value: 'kurtarildi', child: Row(children: [Icon(Icons.verified_user_outlined, color: Colors.blue.shade700), const SizedBox(width: 8), const Text('Kurtarıldı İşaretle')])));
        menuItems.add(const PopupMenuDivider());
      } else { // Hem onaylı hem kurtarılmışsa
        menuItems.add(PopupMenuItem(value: 'kurtarildi_iptal', child: Row(children: [Icon(Icons.cancel_outlined, color: Colors.blue.shade700), const SizedBox(width: 8), const Text('Kurtarıldı İptal')])));
        menuItems.add(const PopupMenuDivider());
      }
      // Her iki onaylı durumda da "Onayı Kaldır" seçeneği sunulur.
      // Eğer kurtarılmışsa, onayı kaldırmak kurtarılmayı da kaldırır.
      menuItems.add(PopupMenuItem(value: 'onay_kaldir', child: Row(children: [Icon(Icons.remove_circle_outline_rounded, color: Colors.orange.shade700), const SizedBox(width: 8), const Text('Onayı Kaldır')])));
    }

    // Her durumda Sil seçeneği en altta
    if (menuItems.isNotEmpty) { // Eğer başka işlem varsa ayırıcı ekle
      menuItems.add(const PopupMenuDivider());
    }
    menuItems.add(PopupMenuItem(value: 'sil', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error), const SizedBox(width: 8), const Text('Sil')])));


    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
      tooltip: "İşlemler",
      onSelected: (String value) async {
        switch (value) {
          case 'sil':
            await _confirmDelete(docId, ihbarAdi);
            break;
          case 'onayla':
            await _updateIhbarStatus(docId, onaylandiMi: true, adminUid: adminUid);
            break;
          case 'kurtarildi':
            await _updateIhbarStatus(docId, kurtarildiMi: true, adminUid: adminUid);
            break;
          case 'onay_kaldir':
          // _updateIhbarStatus içinde onay kaldırılınca kurtarılma durumu da false'a çekiliyor.
            await _updateIhbarStatus(docId, onaylandiMi: false, adminUid: adminUid);
            break;
          case 'kurtarildi_iptal':
            await _updateIhbarStatus(docId, kurtarildiMi: false, adminUid: adminUid);
            break;
        }
      },
      itemBuilder: (BuildContext context) => menuItems,
    );
  }
}