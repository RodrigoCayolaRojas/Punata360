import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CensoTransporteScreen extends StatefulWidget {
  const CensoTransporteScreen({super.key});

  @override
  State<CensoTransporteScreen> createState() => _CensoTransporteScreenState();
}

class _CensoTransporteScreenState extends State<CensoTransporteScreen> {
  final TextEditingController _nombreController = TextEditingController();
  String _tipoSeleccionado = 'Taxi Local';
  double? _latitud;
  double? _longitud;
  bool _obteniendoUbicacion = false;

  final List<String> _tiposTransporte = ['Taxi Local', 'Trufi Interprovincial', 'Micro', 'Bus'];

  Future<void> _obtenerUbicacionActual() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) throw Exception('Permiso denegado');
      }
      Position posicion = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
        _obteniendoUbicacion = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Ubicación capturada!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _obteniendoUbicacion = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _guardarEnBaseDeDatos() {
    if (_nombreController.text.isEmpty || _latitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta nombre o ubicación'), backgroundColor: Colors.orange));
      return;
    }
    final datosAguardar = {
      'nombre': _nombreController.text,
      'tipo': _tipoSeleccionado,
      'ubicacion': {'latitud': _latitud, 'longitud': _longitud},
      'fechaRegistro': DateTime.now().toString(),
    };
    print("=== LISTO PARA ENVIAR A BD ===");
    print(datosAguardar);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos guardados localmente'), backgroundColor: Colors.blue));
    
    // Limpiar formulario para el siguiente registro
    _nombreController.clear();
    setState(() {
      _latitud = null;
      _longitud = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Censo de Líneas'), backgroundColor: Colors.black87, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Permite hacer scroll si el teclado tapa la pantalla
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Datos de la Línea', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre (Ej: Trans Arani)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.directions_car)),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de Servicio', border: OutlineInputBorder(), prefixIcon: Icon(Icons.merge_type)),
                items: _tiposTransporte.map((String tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                onChanged: (String? nuevoValor) => setState(() => _tipoSeleccionado = nuevoValor!),
              ),
              const SizedBox(height: 30),
              const Text('Ubicación de la Parada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Text(_latitud == null ? 'GPS no capturado' : 'Lat: $_latitud \nLng: $_longitud', textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _obteniendoUbicacion ? null : _obtenerUbicacionActual,
                      icon: _obteniendoUbicacion ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.gps_fixed),
                      label: Text(_obteniendoUbicacion ? 'Buscando...' : 'Capturar GPS'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _guardarEnBaseDeDatos,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('GUARDAR LÍNEA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}