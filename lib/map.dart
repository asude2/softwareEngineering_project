import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HaritaSayfasi extends StatelessWidget {
  const HaritaSayfasi({super.key});

  void _showMarkerDetailsDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    String aciklama = data['aciklama'] as String? ?? 'Açıklama yok';
    String ihbarEdilenAdSoyad = data['ihbar_edilen_ad_soyad'] as String? ?? 'Belirtilmemiş';
    String il = data['il'] as String? ?? 'Belirtilmemiş';
    String ilce = data['ilce'] as String? ?? 'Belirtilmemiş';
    String detayliAdres = data['detayli_adres'] as String? ?? 'Belirtilmemiş';

    String formattedDate = "Tarih bilgisi yok";
    if (data.containsKey('tarih') && data['tarih'] != null && data['tarih'] is Timestamp) {
      DateTime date = (data['tarih'] as Timestamp).toDate();
      try {
        formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date);
      } catch (e) {
        formattedDate = "${date.day}/${date.month}/${date.year}";
      }
    }

    GeoPoint? geoPoint = data.containsKey('konum') ? data['konum'] as GeoPoint? : null;
    String konumStr = "Konum bilgisi yok";
    if (geoPoint != null) {
      konumStr = "Lat: ${geoPoint.latitude.toStringAsFixed(5)}, Lon: ${geoPoint.longitude.toStringAsFixed(5)}";
    }

    bool onaylandi = data.containsKey('onaylandiMi') ? data['onaylandiMi'] as bool : false;
    bool kurtarildi = data.containsKey('kurtarildiMi') ? data['kurtarildiMi'] as bool : false;
    String durumMesaji = "Durum: Onay Bekliyor";
    if (kurtarildi) {
      durumMesaji = "Durum: Kurtarıldı";
    } else if (onaylandi) {
      durumMesaji = "Durum: Onaylandı (Kurtarılmayı Bekliyor)";
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ihbarEdilenAdSoyad.isNotEmpty ? ihbarEdilenAdSoyad : "İhbar Detayı"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Açıklama: $aciklama'),
                const SizedBox(height: 8),
                Text('İl: $il'),
                Text('İlçe: $ilce'),
                Text('Detaylı Adres: $detayliAdres'),
                const SizedBox(height: 8),
                Text('Koordinatlar: $konumStr'),
                const SizedBox(height: 8),
                Text('İhbar Tarihi: $formattedDate'),
                const SizedBox(height: 8),
                Text(durumMesaji, style: TextStyle(fontWeight: FontWeight.bold, color: kurtarildi ? Colors.green : (onaylandi ? Colors.blue : Colors.orange))),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> ihbarStream = FirebaseFirestore.instance
        .collection('ihbarlar')
        .where('onaylandiMi', isEqualTo: true) // SADECE ONAYLANMIŞ İHBARLAR
    // .orderBy('kurtarildiMi') // Önce kurtarılmayanları göstermek için (opsiyonel)
        .orderBy('tarih', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onaylanmış İhbar Haritası'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ihbarStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print('Firestore Stream Hata (Harita): ${snapshot.error}');
            return Center(
                child: Text(
                    'İhbarlar yüklenirken bir hata oluştu: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<fm.Marker> ihbarMarkerlari = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (var document in snapshot.data!.docs) {
              Map<String, dynamic> data =
              document.data()! as Map<String, dynamic>;

              bool kurtarildi = data.containsKey('kurtarildiMi') ? data['kurtarildiMi'] as bool : false;

              if (data.containsKey('konum') && data['konum'] != null && data['konum'] is GeoPoint) {
                GeoPoint geoPoint = data['konum'] as GeoPoint;

                Color markerColor = kurtarildi ? Colors.green.shade700 : Colors.redAccent;
                IconData markerIcon = kurtarildi ? Icons.health_and_safety_outlined : Icons.location_on_sharp;

                ihbarMarkerlari.add(
                  fm.Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(geoPoint.latitude, geoPoint.longitude),
                    child: GestureDetector(
                      onTap: () {
                        print('Marker tıklandı (Harita): ${document.id}');
                        _showMarkerDetailsDialog(context, data, document.id);
                      },
                      child: Tooltip(
                        message: '${data['aciklama'] as String? ?? 'Detay için tıkla'}\nDurum: ${kurtarildi ? "Kurtarıldı" : "Yardım Bekliyor"}',
                        child: Icon(
                          markerIcon,
                          color: markerColor,
                          size: 50.0,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                print(
                    'Uyarı (Harita): ${document.id} ID\'li onaylı ihbar için "konum" alanı eksik veya GeoPoint değil.');
              }
            }
          } else {
            print('Firestore (Harita): Gösterilecek onaylı ihbar bulunamadı veya veri boş.');
          }
          print('Oluşturulan onaylı marker sayısı: ${ihbarMarkerlari.length}');

          if (ihbarMarkerlari.isEmpty && (!snapshot.hasData || snapshot.data!.docs.isEmpty)) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Haritada gösterilecek onaylı ihbar bulunamadı.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            ));
          }

          return fm.FlutterMap(
            options: fm.MapOptions(
              initialCenter: const LatLng(38.9637, 35.2433),
              initialZoom: 5.5,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.depsis_project', // Kendi paket adınız
              ),
              fm.MarkerLayer(
                markers: ihbarMarkerlari,
              ),
            ],
          );
        },
      ),
    );
  }
}
