// REPLACE YOUR ENTIRE lib/screens/participant/find_group_screen.dart FILE WITH THIS

import '../../api_service.dart';
import '../../models/yoga_group.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:yoga_app/generated/app_localizations.dart';

class FindGroupScreen extends StatefulWidget {
  const FindGroupScreen({super.key});

  @override
  State<FindGroupScreen> createState() => _FindGroupScreenState();
}

class _FindGroupScreenState extends State<FindGroupScreen> {
  Position? _currentPosition;
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  List<YogaGroup> _groups = [];
  bool _isLoading = false;
  bool _searchPerformed = false;
  bool _isMapView = false;
  String _groupType = 'all'; // State for group type filter

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
      // Search nearby groups on initial load
      await _searchGroups(isInitialLoad: true, groupType: 'all');
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

  Future<void> _searchGroups(
      {bool isInitialLoad = false, String? groupType}) async {
    final query = _searchController.text.trim();
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _searchPerformed = true;
      _groups = [];
    });

    // Use the passed groupType, or the state's _groupType
    final typeToSearch = groupType ?? _groupType;

    try {
      final results = await apiService.getGroups(
        search: query,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        groupType: typeToSearch,
      );
      if (mounted) setState(() => _groups = results);
    } catch (e) {
      if (mounted) {
        _showError(
            'Search failed: ${e.toString().replaceFirst("Exception: ", "")}');
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
        _showError(
            'Failed to join group: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGroupInfoSnackBar(YogaGroup group) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(group.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  child:
                      const Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
              ),
            );
          }).whereType<Marker>().toList(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final l10n = AppLocalizations.of(context)!;
    if (!_searchPerformed) {
      return Center(
        child: Text(l10n.enterSearchTerm),
      );
    }
    if (_groups.isEmpty && !_isLoading) {
      return Center(
        child: Text(l10n.noGroupsFoundSearch),
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
                Text(group.displayLocation),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchPlaceholder,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed:
                      _isLoading ? null : () => _searchGroups(groupType: _groupType),
                ),
              ),
              onSubmitted: (_) => _searchGroups(groupType: _groupType),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'offline', label: Text('Offline')),
                ButtonSegment(value: 'online', label: Text('Online')),
              ],
              selected: {_groupType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _groupType = newSelection.first;
                });
                _searchGroups(groupType: _groupType);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false, icon: Icon(Icons.list), label: Text(l10n.list)),
                ButtonSegment(
                    value: true, icon: Icon(Icons.map), label: Text(l10n.map)),
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
}