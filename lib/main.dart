import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializar Firebase
  runApp(const PunataApp());
}

class PunataApp extends StatelessWidget {
  const PunataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Punata Transportes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MapaPunataScreen(),
    );
  }
}

class MapaPunataScreen extends StatefulWidget {
  const MapaPunataScreen({super.key});

  @override
  State<MapaPunataScreen> createState() => _MapaPunataScreenState();
}

class _MapaPunataScreenState extends State<MapaPunataScreen> {
  static const LatLng punataCentro = LatLng(-17.5446, -65.8340);
  String categoriaActiva = 'Transporte';

  List<Marker> _marcadores = [];
  List<Polyline> _rutas = [];
  
  // ¡NUEVO! Controla la conexión en vivo para poder cancelarla al cambiar de pestaña
  StreamSubscription? _suscripcionFirebase; 

  @override
  void initState() {
    super.initState();
    // Al iniciar, cargamos la categoría que está por defecto ('Transporte')
    _cargarPinesPorCategoria(categoriaActiva);
  }

  // ¡NUEVA FUNCIÓN! Reemplaza a _cargarDatosMVP
  void _cargarPinesPorCategoria(String categoria) {
    // 1. Cancelamos la búsqueda anterior
    _suscripcionFirebase?.cancel();

    // 2. Vaciamos el mapa inmediatamente al tocar el botón
    setState(() {
      _marcadores = [];
    });

    // 3. Vamos a Firebase a buscar solo los de la categoría elegida
    _suscripcionFirebase = FirebaseFirestore.instance
        .collection('paradas')
        .where('categoria', isEqualTo: categoria)
        .snapshots()
        .listen((snapshot) {
      
      List<Marker> nuevosMarcadores = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('geopoint') && data['geopoint'] != null) {
          GeoPoint geo = data['geopoint'];
          
          IconData icono = Icons.location_on;
          Color colorIcono = Colors.red;

          if (categoria == 'Transporte') {
            icono = data['tipo'] == 'Taxi Local' ? Icons.local_taxi : Icons.directions_bus;
            colorIcono = Colors.blueAccent;
          } else if (categoria == 'Comida') {
            icono = Icons.restaurant;
            colorIcono = Colors.orange;
          } else if (categoria == 'Turismo') {
            icono = Icons.park;
            colorIcono = Colors.green;
          } else if (categoria == 'Hoteles') {
            icono = Icons.hotel;
            colorIcono = Colors.purple;
          }

          nuevosMarcadores.add(
            Marker(
              point: LatLng(geo.latitude, geo.longitude),
              width: 45,
              height: 45,
              child: Icon(icono, color: colorIcono, size: 40),
            ),
          );
        }
      }

      // 4. Dibujamos los nuevos pines
      setState(() {
        _marcadores = nuevosMarcadores;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA
          FlutterMap(
            options: const MapOptions(
              initialCenter: punataCentro,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tuempresa.punataapp',
              ),
              PolylineLayer(polylines: _rutas), 
              MarkerLayer(markers: _marcadores), 
            ],
          ),

          // 2. BARRA SUPERIOR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Buscar destinos...', 
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.mic, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.blueGrey, size: 26),
                  ),
                ),
              ],
            ),
          ),

          // 3. MENÚ INFERIOR
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _construirBotonMenu(Icons.directions_car, 'Transporte'),
                  _construirBotonMenu(Icons.park, 'Turismo'),
                  _construirBotonMenu(Icons.restaurant, 'Comida'),
                  _construirBotonMenu(Icons.hotel, 'Hoteles'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonMenu(IconData icono, String texto) {
    bool activo = categoriaActiva == texto;
    return GestureDetector(
      onTap: () {
        setState(() {
          categoriaActiva = texto;
        });
        // ¡NUEVO! Aquí es donde llamamos a Firebase para limpiar y traer los datos de la nueva pestaña
        _cargarPinesPorCategoria(texto); 
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activo ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
              border: activo ? Border.all(color: Colors.red, width: 2) : null,
            ),
            child: Icon(icono, color: activo ? Colors.red : Colors.grey[700], size: 28),
          ),
          const SizedBox(height: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: activo ? Colors.red : Colors.grey[700],
              fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }
}