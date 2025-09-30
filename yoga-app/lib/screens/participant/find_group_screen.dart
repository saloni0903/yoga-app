import '../../api_service.dart';
import '../../models/yoga_group.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';

class FindGroupScreen extends StatefulWidget {
  const FindGroupScreen({super.key});

  @override
  State<FindGroupScreen> createState() => _FindGroupScreenState();
}


class _FindGroupScreenState extends State<FindGroupScreen> {
  Position? _currentPosition;
  final MapController _mapController = MapController();

  Widget _buildListView() {
    if (!_searchPerformed && _groups.isEmpty) {
      return const Center(child: Text('Search for a yoga group to begin.'));
    }
    if (_searchPerformed && _groups.isEmpty) {
      return const Center(child: Text('No groups found.'));
    }
    return ListView.builder(
      itemCount: _groups.length,
      itemBuilder: (_, i) {
        final g = _groups[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(g.locationText),
                      if (g.distance != null) ...[ // Display distance if available
                        const SizedBox(height: 4),
                        Text(
                          '${(g.distance! / 1000).toStringAsFixed(1)} km away',
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _join(g.id),
                  child: const Text('Join'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(22.7196, 75.8577), // Default to Indore
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: _groups.map((group) {
            return Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(group.latitude!, group.longitude!),
              child: GestureDetector( // Use GestureDetector to make the icon tappable
                onTap: () => _showGroupInfoSnackBar(group),
                child: Tooltip(
                  message: group.name,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showGroupInfoSnackBar(YogaGroup group) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide any previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'JOIN',
          textColor: Colors.white,
          onPressed: () {
            _join(group.id);
          },
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      // Optional: perform an initial search for nearby groups on load
      // _searchGroups(); 
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _searchController = TextEditingController();
  List<YogaGroup> _groups = [];
  bool _isLoading = false;
  bool _searchPerformed = false;
  bool _isMapView = false; // To toggle between list and map

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _searchGroups() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    FocusScope.of(context).unfocus();
    setState(() {
    _isLoading = true;
    _searchPerformed = true;
  });
    try {
      final results = await apiService.getGroups(
        search: query,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
      if (mounted) setState(() => _groups = results);
    } catch (e) {
      if (mounted)
        _showError(
          'Search failed: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    } finally {
      if (mounted) setState(() => _isLoading  = false);
    }
  }

  Future<void> _join(String groupId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading  = true);
    try {
      await apiService.joinGroup(groupId: groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined group!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted)
        _showError(
          'Failed to join group: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Yoga Group'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by location or group name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchGroups,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _searchGroups(),
            ),
          ),
          
          // --- VIEW TOGGLE ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.list), label: Text('List')),
                ButtonSegment(value: true, icon: Icon(Icons.map), label: Text('Map')),
              ],
              selected: {_isMapView},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _isMapView = newSelection.first;
                });
              },
            ),
          ),
          
          if (_isLoading) const LinearProgressIndicator(),

          // --- DYNAMIC VIEW (LIST OR MAP) ---
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }
}
