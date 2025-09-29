// lib/screens/participant/find_group_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../api_service.dart';
import '../../models/yoga_group.dart';

class FindGroupScreen extends StatefulWidget {
  const FindGroupScreen({super.key});

  @override
  State<FindGroupScreen> createState() => _FindGroupScreenState();
}

class _FindGroupScreenState extends State<FindGroupScreen> {
  final _searchController = TextEditingController();
  List<YogaGroup> _groups = [];
  bool _isLoading = false;
  bool _searchPerformed = false;
  bool _isMapView = false; // To toggle between list and map

  Future<void> _searchGroups() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    FocusScope.of(context).unfocus(); // Hide keyboard

    setState(() {
      _isLoading = true;
      _searchPerformed = true;
    });

    try {
      // Use the existing text-based search from your ApiService
      final results = await apiService.getGroups(search: query);
      if (mounted) setState(() => _groups = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
        );
      }
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
            padding: const EdgeInsets.all(16.0),
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
          ToggleButtons(
            isSelected: [_isMapView == false, _isMapView == true],
            onPressed: (index) {
              setState(() {
                _isMapView = index == 1;
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(Icons.list), SizedBox(width: 8), Text('List View')])),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(Icons.map), SizedBox(width: 8), Text('Map View')])),
            ],
          ),
          const SizedBox(height: 16),

          // --- DYNAMIC CONTENT AREA ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  // --- LIST VIEW WIDGET ---
  // Widget _buildListView() {
  //   if (!_searchPerformed) {
  //     return const Center(child: Text('Start by searching for a group near you.'));
  //   }
  //   if (_groups.isEmpty) {
  //     return const Center(child: Text('No groups found for your search.'));
  //   }
  //   return ListView.builder(
  //     itemCount: _groups.length,
  //     itemBuilder: (context, index) {
  //       final group = _groups[index];
  //       return Card(
  //         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //         child: ListTile(
  //           title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
  //           subtitle: Text('${group.locationText}\n${group.timingText}'),
  //           isThreeLine: true,
  //           trailing: ElevatedButton(
  //             onPressed: () { /* TODO: Implement join group logic */ },
  //             child: const Text('Join'),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  // --- LIST VIEW WIDGET ---
  Widget _buildListView() {
    if (!_searchPerformed) {
      return const Center(
          child: Text('Start by searching for a group near you.'));
    }
    if (_groups.isEmpty) {
      return const Center(child: Text('No groups found for your search.'));
    }
    return ListView.builder(
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          clipBehavior: Clip.antiAlias, // Helps with rendering
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Use Expanded to make the text take up available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(group.locationText),
                      const SizedBox(height: 4),
                      Text(
                        group.timingText,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16), // Spacing
                // The button that a participant can press
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement join group logic from Provider
                  },
                  child: const Text('Join'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- MAP VIEW WIDGET ---
  Widget _buildMapView() {
     // For your pitch, this shows the map feature exists.
     // It will work perfectly on a mobile device/emulator.
     // On the web, it will show an error until you enable billing for your Google API Key.
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(22.7196, 75.8577), // Default to Indore
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        MarkerLayer(
          markers: _groups
              .where((g) => g.latitude != null && g.longitude != null)
              .map((group) => Marker(
                    point: LatLng(group.latitude!, group.longitude!),
                    width: 80, height: 80,
                    child: Icon(Icons.location_pin, color: Colors.red.shade400, size: 40),
                  ))
              .toList(),
        ),
      ],
    );
  }
}