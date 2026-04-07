import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'screens/login_screen.dart'; 
import 'package:firebase_core/firebase_core.dart'; // Importar
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _cargarDatosMVP();
  }

  void _cargarDatosMVP() {
    setState(() {
      _marcadores = [
        const Marker(
          point: LatLng(-17.5450, -65.8345),
          width: 40,
          height: 40,
          child: Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
        const Marker(
          point: LatLng(-17.5420, -65.8380),
          width: 40,
          height: 40,
          child: Icon(Icons.directions_bus, color: Colors.blue, size: 40),
        ),
      ];

      _rutas = [
        Polyline(
          points: const [
            LatLng(-17.5400, -65.8400),
            LatLng(-17.5420, -65.8380),
            LatLng(-17.5446, -65.8340),
          ],
          color: Colors.blue,
          strokeWidth: 5.0,
        ),
      ];
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
              PolylineLayer(polylines: _rutas), // Mostramos rutas si hay
              MarkerLayer(markers: _marcadores), // Siempre mostramos los marcadores activos
            ],
          ),

          // =========================================================
          // 2. NUEVA BARRA SUPERIOR (Buscador + Perfil)
          // =========================================================
          Positioned(
         
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // BUSCADOR (Toma el espacio restante con Expanded)
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
                const SizedBox(width: 10), // Espacio entre buscador y perfil
                
                // BOTÓN DE PERFIL (Para acceder al Login / Censo)
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