import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressSearchMapScreen extends StatefulWidget {

  const AddressSearchMapScreen({Key? key}) : super(key: key);

  @override
  State<AddressSearchMapScreen> createState() => _AddressSearchMapScreenState();
}

class _AddressSearchMapScreenState extends State<AddressSearchMapScreen> {
  final TextEditingController _addressController = TextEditingController();
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Nominatim API'sine istek gönderme ve marker ekleme
  Future<void> _searchAndAddMarker(String address) async {
    if (address.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen bir adres girin.';
      });
      _showErrorSnackBar(_errorMessage!);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Nominatim API URL'i
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=jsonv2&addressdetails=1&limit=1');

    try {

      final response = await http.get(url,
          headers: {'User-Agent': 'DepsisProjesiFlutterApp/1.0 (iletisim@example.com)'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final result = data[0];
          final lat = double.tryParse(result['lat'].toString());
          final lon = double.tryParse(result['lon'].toString());
          final displayName = result['display_name'] ?? 'Belirtilen Konum';

          if (lat != null && lon != null) {
            final newMarker = Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(lat, lon),
              child: Tooltip( // Marker üzerine gelince bilgi gösterir
                message: displayName,
                child: Icon(Icons.location_pin, color: Colors.redAccent, size: 40),
              ),
            );

            setState(() {
              _markers.clear();
              _markers.add(newMarker);
              _mapController.move(LatLng(lat, lon), 15.0); // Haritayı yeni konuma taşı ve yakınlaştır
            });
          } else {
            throw Exception('Koordinat bilgisi alınamadı.');
          }
        } else {
          setState(() {
            _errorMessage = 'Adres bulunamadı. Lütfen daha spesifik bir adres deneyin.';
          });
          _showErrorSnackBar(_errorMessage!);
        }
      } else {
        setState(() {
          _errorMessage = 'Servis hatası: ${response.statusCode}. Lütfen sonra tekrar deneyin.';
        });
        _showErrorSnackBar(_errorMessage!);
      }
    } catch (e) {
      print('Hata oluştu: $e');
      setState(() {
        _errorMessage = 'Adres aranırken bir hata oluştu: $e';
      });
      _showErrorSnackBar(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adres ile Konum Bul'),
        backgroundColor: Colors.teal, // Temanıza uygun bir renk seçin
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Örn: Atatürk Caddesi, Ankara',
                      labelText: 'Aranacak Adres',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _addressController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _addressController.clear();
                          setState(() {

                          });
                        },
                      )
                          : null,
                    ),
                    onSubmitted: (value) { // Enter'a basınca ara
                      if (value.isNotEmpty) {
                        _searchAndAddMarker(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Bul'),
                  onPressed: _isLoading
                      ? null // Yükleniyorsa butonu pasif yap
                      : () {
                    _searchAndAddMarker(_addressController.text);
                    // Klavyeyi gizle
                    FocusScope.of(context).unfocus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          // if (_errorMessage != null && !_isLoading) // Hata mesajını burada da gösterebilirsiniz
          //   Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: Text(_errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16)),
          //   ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(39.92077, 32.85411), // Varsayılan merkez (Ankara)
                initialZoom: 6.0, // Haritanın başlangıç zoom seviyesi

              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
