import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// main.dart'taki tema renklerine veya Google Fonts'a erişmek için
// import 'package:google_fonts/google_fonts.dart'; // Eğer diyalogda özel font isterseniz

class HaritaSayfasi extends StatelessWidget {
  const HaritaSayfasi({super.key});

  void _showMarkerDetailsDialog(BuildContext context, Map<String, dynamic> data, String docId) {
    // Tema renklerine ve text stillerine erişim
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

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

    String durumMesaji;
    Color durumRenk;

    if (kurtarildi) {
      durumMesaji = "Durum: Kurtarıldı";
      durumRenk = Colors.green.shade700;
    } else if (onaylandi) {
      durumMesaji = "Durum: Onaylandı (Yardım Bekliyor)";
      durumRenk = Colors.blue.shade700;
    } else {
      durumMesaji = "Durum: Onay Bekliyor"; // Bu sayfada normalde görünmez ama genel bir yapı
      durumRenk = Colors.orange.shade700;
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Tema'dan gelen AlertDialog stilini kullanır (main.dart'ta tanımladık)
          title: Text(
            ihbarEdilenAdSoyad.isNotEmpty ? ihbarEdilenAdSoyad : "İhbar Detayı",
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface), // Temadan gelen stil
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow(context, "Açıklama:", aciklama),
                const SizedBox(height: 10),
                _buildDetailRow(context, "İl:", il),
                _buildDetailRow(context, "İlçe:", ilce),
                _buildDetailRow(context, "Detaylı Adres:", detayliAdres),
                const SizedBox(height: 10),
                _buildDetailRow(context, "Koordinatlar:", konumStr),
                const SizedBox(height: 10),
                _buildDetailRow(context, "İhbar Tarihi:", formattedDate),
                const SizedBox(height: 12),
                Text(
                  durumMesaji,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: durumRenk,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Kapat'), // Temadan stil alır
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Diyalog içeriği için yardımcı widget
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        children: <TextSpan>[
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: value),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> ihbarStream = FirebaseFirestore.instance
        .collection('ihbarlar')
        .where('onaylandiMi', isEqualTo: true)
        .orderBy('tarih', descending: true)
        .snapshots();

    // Marker boyutları
    const double markerWidth = 60.0; // Önceki 80.0'dı
    const double markerHeight = 60.0; // Önceki 80.0'dı
    const double markerIconSize = 35.0; // Önceki 50.0'dı

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onaylanmış İhbar Haritası'),
        // backgroundColor ve foregroundColor temadan gelecek (main.dart'ta ayarlandı)
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ihbarStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print('Firestore Stream Hata (Harita): ${snapshot.error}');
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'İhbarlar yüklenirken bir hata oluştu.\nLütfen daha sonra tekrar deneyiniz.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }

          List<fm.Marker> ihbarMarkerlari = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (var document in snapshot.data!.docs) {
              Map<String, dynamic> data =
              document.data()! as Map<String, dynamic>;

              bool kurtarildi = data.containsKey('kurtarildiMi') ? data['kurtarildiMi'] as bool : false;

              if (data.containsKey('konum') && data['konum'] != null && data['konum'] is GeoPoint) {
                GeoPoint geoPoint = data['konum'] as GeoPoint;

                // Renk ve ikonları durumuna göre belirleyelim
                Color markerRenk;
                IconData markerIkonData;

                if (kurtarildi) {
                  markerRenk = Colors.green.shade600; // Daha canlı bir yeşil
                  markerIkonData = Icons.check_circle_outline_rounded; // Kurtarıldı için farklı ikon
                } else {
                  // Onaylı ama henüz kurtarılmamış
                  markerRenk = Theme.of(context).colorScheme.error; // Temadan hata/acil durum rengi (kırmızı tonu)
                  markerIkonData = Icons.location_pin; // Standart konum pini (daha belirgin)
                }


                ihbarMarkerlari.add(
                  fm.Marker(
                    width: markerWidth,   // Optimize edilmiş genişlik
                    height: markerHeight,  // Optimize edilmiş yükseklik
                    point: LatLng(geoPoint.latitude, geoPoint.longitude),
                    child: GestureDetector(
                      onTap: () {
                        print('Marker tıklandı (Harita): ${document.id}');
                        _showMarkerDetailsDialog(context, data, document.id);
                      },
                      child: Tooltip(
                        message: '${data['aciklama'] as String? ?? 'Detay için tıkla'}\nDurum: ${kurtarildi ? "Kurtarıldı" : "Yardım Bekliyor"}',
                        preferBelow: false, // Tooltip'i marker'ın üstünde göster
                        child: Icon(
                          markerIkonData,
                          color: markerRenk,
                          size: markerIconSize, // Optimize edilmiş ikon boyutu
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
          }

          if (ihbarMarkerlari.isEmpty) { // Veri var ama marker oluşturulamadıysa veya hiç veri yoksa
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Haritada gösterilecek onaylı ihbar bulunamadı.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                ));
          }

          return fm.FlutterMap(
            options: fm.MapOptions(
              initialCenter: const LatLng(39.15, 35.5), // Türkiye için biraz daha merkezi bir başlangıç
              initialZoom: 5.8, // Biraz daha yakınlaştırılmış başlangıç zoom'u
              minZoom: 3.0, // Minimum zoom seviyesi
              maxZoom: 18.0, // Maksimum zoom seviyesi
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', // Standart OpenStreetMap
                subdomains: const ['a', 'b', 'c'], // OSM için standart alt alan adları
                userAgentPackageName: 'com.example.depsis_project', // Kendi paket adınızla değiştirin
                // Tile provider options:
                // tileProvider: fm.NetworkTileProvider(), // Varsayılan
              ),
              fm.MarkerLayer(
                markers: ihbarMarkerlari,
                rotate: false, // Marker'lar harita ile dönmesin (genellikle istenmez)
              ),
            ],
          );
        },
      ),
    );
  }
}