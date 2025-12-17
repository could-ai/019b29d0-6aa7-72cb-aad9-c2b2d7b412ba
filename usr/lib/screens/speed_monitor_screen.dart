import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class SpeedMonitorScreen extends StatefulWidget {
  const SpeedMonitorScreen({super.key});

  @override
  State<SpeedMonitorScreen> createState() => _SpeedMonitorScreenState();
}

class _SpeedMonitorScreenState extends State<SpeedMonitorScreen> {
  // Velocidad actual en km/h
  double _currentSpeed = 0.0;
  
  // Límite de velocidad simulado (en una app real vendría de una API de mapas)
  double _speedLimit = 50.0;
  
  // Stream subscription para la posición
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Estado de permisos
  String _statusMessage = "Esperando GPS...";
  bool _isSpeeding = false;

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = "El GPS está desactivado.");
      return;
    }

    // 2. Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = "Permiso de ubicación denegado.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusMessage = "Permisos denegados permanentemente.");
      return;
    }

    // 3. Iniciar el stream de posición
    // Usamos LocationSettings para alta precisión (necesario para velocidad precisa)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // Actualizar con cada movimiento
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      // La velocidad viene en metros por segundo (m/s).
      // Multiplicamos por 3.6 para convertir a km/h.
      double speedKmH = position.speed * 3.6;
      
      // Filtrar ruido: si la velocidad es negativa o muy baja, poner 0
      if (speedKmH < 1.0) speedKmH = 0.0;

      setState(() {
        _currentSpeed = speedKmH;
        _statusMessage = "Monitoreando...";
        _checkSpeedLimit();
      });
    });
  }

  void _checkSpeedLimit() {
    if (_currentSpeed > _speedLimit) {
      _isSpeeding = true;
    } else {
      _isSpeeding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definir colores según si excede el límite
    final Color backgroundColor = _isSpeeding ? Colors.red.shade900 : Colors.white;
    final Color textColor = _isSpeeding ? Colors.white : Colors.black;
    final Color circleColor = _isSpeeding ? Colors.redAccent : Colors.blueAccent;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Monitor de Velocidad'),
        backgroundColor: _isSpeeding ? Colors.red.shade800 : Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: _isSpeeding ? Colors.white : Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicador de Estado
            Text(
              _statusMessage,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Círculo de Velocidad
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: circleColor,
                  width: 10,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentSpeed.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    "km/h",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // Alerta Visual Grande
            if (_isSpeeding)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning, color: Colors.red, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "¡VELOCIDAD EXCEDIDA!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Selector de Límite de Velocidad (Simulación)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSpeeding ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    "Límite de Velocidad (Simulado)",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLimitButton(30, textColor),
                      _buildLimitButton(50, textColor),
                      _buildLimitButton(80, textColor),
                      _buildLimitButton(100, textColor),
                      _buildLimitButton(120, textColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitButton(double limit, Color textColor) {
    final bool isSelected = _speedLimit == limit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _speedLimit = limit;
            _checkSpeedLimit();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? (_isSpeeding ? Colors.white : Colors.blue) : Colors.transparent,
            border: Border.all(color: isSelected ? Colors.transparent : textColor),
            shape: BoxShape.circle,
          ),
          child: Text(
            limit.toInt().toString(),
            style: TextStyle(
              color: isSelected ? (_isSpeeding ? Colors.red : Colors.white) : textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
