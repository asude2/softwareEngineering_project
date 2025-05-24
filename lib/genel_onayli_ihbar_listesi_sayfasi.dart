import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GenelOnayliIhbarListesiSayfasi extends StatefulWidget {
  const GenelOnayliIhbarListesiSayfasi({super.key});
  static const String routeName = '/onayli-ihbar-listesi';

  @override
  State<GenelOnayliIhbarListesiSayfasi> createState() => _GenelOnayliIhbarListesiSayfasiState();
}

class _GenelOnayliIhbarListesiSayfasiState extends State<GenelOnayliIhbarListesiSayfasi> {
  String filterName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onaylanmış İhbarlar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'İsim ile filtrele',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  filterName = val.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ihbarlar')
                  .where('onaylandiMi', isEqualTo: true)
              // burada filtreleme yapacağız
              // ancak firestore'da partial text search yok, bu yüzden tam eşleşme veya prefix ile yapılabilir
              // örnek prefix için:
              // .where('ihbar_edilen_ad_soyad', isGreaterThanOrEqualTo: filterName)
              // .where('ihbar_edilen_ad_soyad', isLessThan: filterName + 'z')
              // ama bu sadece prefix için geçerli
              // boş filtre için tümü
                  .orderBy('tarih', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // builder kodu aynı kalabilir, sadece listeyi filtrelemeden önce
                // eğer filterName boş değilse listeyi filtreleyebiliriz.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("İhbarlar yüklenirken bir hata oluştu: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz onaylanmış bir ihbar bulunmamaktadır."));
                }

                final docs = snapshot.data!.docs;

                final filteredDocs = filterName.isEmpty
                    ? docs
                    : docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['ihbar_edilen_ad_soyad'] as String? ?? '';
                  return name.toLowerCase().contains(filterName.toLowerCase());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("Filtreye uygun ihbar bulunamadı."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // aynı formatlama işlemleri burada olacak
                    String formattedDate = "Tarih bilgisi yok";
                    if (data.containsKey('tarih') && data['tarih'] != null && data['tarih'] is Timestamp) {
                      DateTime date = (data['tarih'] as Timestamp).toDate();
                      try {
                        formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date);
                      } catch (e) {
                        formattedDate = "${date.day}/${date.month}/${date.year}";
                      }
                    }

                    String konumText = 'Konum bilgisi yok';
                    Color konumRenk = Colors.grey[600]!;
                    FontStyle konumFontStyle = FontStyle.italic;

                    if (data.containsKey('konum') && data['konum'] != null && data['konum'] is GeoPoint) {
                      GeoPoint geoPoint = data['konum'] as GeoPoint;
                      konumText = 'Konum: ${geoPoint.latitude.toStringAsFixed(4)}, ${geoPoint.longitude.toStringAsFixed(4)}';
                      konumRenk = Colors.blueGrey[700]!;
                      konumFontStyle = FontStyle.normal;
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        leading: Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
