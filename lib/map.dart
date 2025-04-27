import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HaritaSayfasi extends StatelessWidget {
  const HaritaSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Türkiye Haritası'),
        backgroundColor: Color(0xFFDC321E),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(38.9637, 35.2433),
          initialZoom: 5.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: LatLng(41.0082, 28.9784), // istanbul
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              Marker(
                width: 40,
                height: 40,
                point: LatLng(38.4237, 27.1428), // izmir
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              Marker(
                width: 40,
                height: 40,
                point: LatLng(39.9208, 32.8541), // ankara
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
