// lib/screens/participant/find_group_screen.dart
// REPLACE THE ENTIRE FILE WITH THIS CORRECTED VERSION

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
  // --- ALL VARIABLES AND METHODS ARE NOW CORRECTLY INSIDE THE CLASS ---

  Position? _currentPosition;
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  List<YogaGroup> _groups = [];
  bool _isLoading = false;
  bool _searchPerformed = false;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      await _searchGroups(isInitialLoad: true);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _searchGroups({bool isInitialLoad = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty && !isInitialLoad) return;
    
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _searchPerformed = true;
      _groups = [];
    });

    try {
      final results = await apiService.getGroups(
        search: query,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
      if (mounted) setState(() => _groups = results);
    } catch (e) {
      if (mounted) {
        _showError('Search failed: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup(String groupId) async {
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await apiService.joinGroup(groupId: groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to join group: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGroupInfoSnackBar(YogaGroup group) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'JOIN',
          textColor: Colors.white,
          onPressed: () {
            _joinGroup(group.id);
          },
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(22.7196, 75.8577),
        initialZoom: 13.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: _groups.map((group) {
            if (group.latitude == null || group.longitude == null) {
              return null;
            }
            return Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(group.latitude!, group.longitude!),
              child: GestureDetector(
                onTap: () => _showGroupInfoSnackBar(group),
                child: Tooltip(
                  message: group.name,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
              ),
            );
          }).whereType<Marker>().toList(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (!_searchPerformed) {
      return const Center(
        child: Text('Enter a search term to find groups.'),
      );
    }
    if (_groups.isEmpty && !_isLoading) {
      return const Center(
        child: Text('No groups found matching your search.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _groups.length,
      itemBuilder: (_, index) {
        final group = _groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(group.locationText),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _joinGroup(group.id),
                    child: const Text('Join Group'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by location or group name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _isLoading ? null : _searchGroups,
                ),
              ),
              onSubmitted: (_) => _searchGroups(),
            ),
          ),
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
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }
} // THIS IS THE FINAL CLOSING BRACE FOR THE CLASS