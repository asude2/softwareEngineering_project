import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IhbarDuzenleSayfasi extends StatefulWidget {
  const IhbarDuzenleSayfasi({super.key});

  @override
  State<IhbarDuzenleSayfasi> createState() => _IhbarDuzenleSayfasiState();
}

class _IhbarDuzenleSayfasiState extends State<IhbarDuzenleSayfasi> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _silIhbar(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emin misiniz?'),
        content: Text('Bu ihbar kalıcı olarak silinecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Hayır')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Evet')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('ihbarlar').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İhbar silindi.')));
    }
  }

  void _duzenleIhbar(BuildContext context, String docId, Map<String, dynamic> currentData) {
    final _adSoyadController = TextEditingController(text: currentData['ihbar_edilen_ad_soyad']);
    final _adresController = TextEditingController(text: currentData['detayli_adres']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('İhbarı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _adSoyadController,
                decoration: InputDecoration(labelText: 'Ad Soyad'),
              ),
              TextField(
                controller: _adresController,
                decoration: InputDecoration(labelText: 'Adres'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('ihbarlar').doc(docId).update({
                'ihbar_edilen_ad_soyad': _adSoyadController.text,
                'detayli_adres': _adresController.text,
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İhbar güncellendi.')));
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return Center(child: Text("Giriş yapmamış kullanıcı"));

    return Scaffold(
      appBar: AppBar(
        title: Text("İhbarlarım"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ihbarlar')
            .where('ihbar_eden_uid', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text("Hiç ihbar bulunamadı."));

          return ListView.separated(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['ihbar_edilen_ad_soyad'] ?? 'Ad Soyad Yok'),
                subtitle: Text(data['detayli_adres'] ?? 'Adres yok'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _duzenleIhbar(context, doc.id, data),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _silIhbar(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
