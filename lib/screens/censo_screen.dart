import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CensoTransporteScreen extends StatefulWidget {
  const CensoTransporteScreen({super.key});

  @override
  State<CensoTransporteScreen> createState() => _CensoTransporteScreenState();
}

class _CensoTransporteScreenState extends State<CensoTransporteScreen> {
  final TextEditingController _nombreController = TextEditingController();
  
  // ¡NUEVO! Variables para controlar ambas categorías
  String _categoriaSeleccionada = 'Transporte';
  String _tipoSeleccionado = 'Taxi Local';
  
  double? _latitud;
  double? _longitud;
  bool _obteniendoUbicacion = false;

  // ¡NUEVO! Lista de categorías principales
  final List<String> _categoriasPrincipales = ['Transporte', 'Turismo', 'Comida', 'Hoteles'];

  // ¡NUEVO! Diccionario con los subtipos dinámicos según la categoría
  final Map<String, List<String>> _tiposPorCategoria = {
    'Transporte': ['Taxi Local', 'Trufi Interprovincial', 'Micro', 'Bus', 'Moto Taxi'],
    'Turismo': ['Plaza Principal', 'Parque', 'Museo', 'Iglesia', 'Monumento', 'Naturaleza'],
    'Comida': ['Restaurante', 'Pensión', 'Comida Rápida', 'Mercado', 'Cafetería'],
    'Hoteles': ['Hotel', 'Residencial', 'Alojamiento', 'Hostal'],
  };

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

  void _guardarEnBaseDeDatos() async {
    if (_nombreController.text.isEmpty || _latitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta nombre o ubicación'), backgroundColor: Colors.orange)
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subiendo a la nube...'), backgroundColor: Colors.blue)
      );

      await FirebaseFirestore.instance.collection('paradas').add({
        'nombre': _nombreController.text,
        'tipo': _tipoSeleccionado,
        'geopoint': GeoPoint(_latitud!, _longitud!),
        'fechaRegistro': FieldValue.serverTimestamp(),
        // ¡NUEVO! Ahora guardamos la categoría real elegida
        'categoria': _categoriaSeleccionada, 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Registro guardado en la nube!'), backgroundColor: Colors.green)
      );

      _nombreController.clear();
      setState(() {
        _latitud = null;
        _longitud = null;
        // Opcionalmente podrías reiniciar las categorías aquí si quieres
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos la lista de subtipos dependiendo de la categoría seleccionada
    List<String> opcionesTipo = _tiposPorCategoria[_categoriaSeleccionada]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro Punata 360'), backgroundColor: Colors.black87, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Datos del Lugar / Servicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              // 1. SELECTOR DE CATEGORÍA PRINCIPAL
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(labelText: 'Categoría Principal', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                items: _categoriasPrincipales.map((String categoria) {
                  return DropdownMenuItem(value: categoria, child: Text(categoria));
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() {
                    _categoriaSeleccionada = nuevoValor!;
                    // Al cambiar la categoría principal, el subtipo debe reiniciarse al primero de la nueva lista
                    _tipoSeleccionado = _tiposPorCategoria[nuevoValor]!.first;
                  });
                },
              ),
              const SizedBox(height: 15),

              // 2. SELECTOR DE SUB-TIPO DINÁMICO
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo Específico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.merge_type)),
                items: opcionesTipo.map((String tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (String? nuevoValor) => setState(() => _tipoSeleccionado = nuevoValor!),
              ),
              const SizedBox(height: 15),

              // 3. NOMBRE DEL LUGAR
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre (Ej: Pensión Doña Mary)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit)),
              ),
              
              const SizedBox(height: 30),
              const Text('Ubicación Exacta GPS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                child: const Text('GUARDAR REGISTRO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}