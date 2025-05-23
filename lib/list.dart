import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IhbarListesi extends StatefulWidget {
  const IhbarListesi({super.key});

  @override
  State<IhbarListesi> createState() => _IhbarListesiState();
}

class _IhbarListesiState extends State<IhbarListesi> {
  String filter = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tüm İhbarlar'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'İsme göre filtrele',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  filter = val.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ihbarlar').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                // verileri al
                var docs = snapshot.data!.docs;

                // filtre uygula
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String isim = data['ihbar_edilen_ad_soyad'] ?? '';
                  return isim.toLowerCase().contains(filter);
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowHeight: 50,
                    dividerThickness: 1,
                    columns: [
                      DataColumn(
                        label: Text(
                          'İsimler',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Adres Bilgileri',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: filteredDocs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String isim = data['ihbar_edilen_ad_soyad'] ?? '';
                      String adres = data['detayli_adres'] ?? '';

                      bool isFiltered = filter.isNotEmpty && isim.toLowerCase().contains(filter);

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              isim,
                              style: TextStyle(
                                color: isFiltered ? Colors.red : Colors.black,
                                fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(adres),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
