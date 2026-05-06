import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final ValueChanged<LatLng> onLocationSelected;

  const LocationPickerMap({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  static const _defaultCenter = LatLng(-34.6037, -58.3816); // Buenos Aires
  static const _defaultZoom = 12.0;

  late final MapController _mapController;
  LatLng? _selectedLocation;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
  }

  Future<void> _useMyLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final locationService = Location();
      bool serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permission = await locationService.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await locationService.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      final locationData = await locationService.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final point = LatLng(locationData.latitude!, locationData.longitude!);
        setState(() => _selectedLocation = point);
        _mapController.move(point, 15.0);
        widget.onLocationSelected(point);
      }
    } catch (_) {
      // Si falla el GPS el usuario puede tocar el mapa manualmente
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedLocation ?? widget.initialLocation ?? _defaultCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _defaultZoom,
                onTap: (_, point) {
                  setState(() => _selectedLocation = point);
                  widget.onLocationSelected(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.warriorpath.app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: FloatingActionButton.small(
                heroTag: 'location_picker_gps',
                onPressed: _loadingLocation ? null : _useMyLocation,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                child: _loadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 20),
              ),
            ),
            if (_selectedLocation == null)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tocá el mapa para fijar la ubicación',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
