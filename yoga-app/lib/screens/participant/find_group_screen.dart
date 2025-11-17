// lib/screens/participant/find_group_screen.dart
import '../../api_service.dart';
import '../../models/yoga_group.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:yoga_app/generated/app_localizations.dart';
import 'package:intl/intl.dart';

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
  String _selectedFilter = 'all'; // 'all', 'online', 'offline'
  String _groupType = 'all'; // State for group type filter

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get filtered groups based on current filter
  List<YogaGroup> get _displayedGroups {
    if (_selectedFilter == 'all') {
      return _groups;
    } else if (_selectedFilter == 'online') {
      return _groups.where((g) => g.groupType == 'online').toList();
    } else {
      return _groups.where((g) => g.groupType == 'offline').toList();
    }
  }

  // Check if map should be disabled
  bool get _isMapDisabled {
    return _selectedFilter == 'online';
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
        'Location permissions are permanently denied, we cannot request permissions.',
      );
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
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _searchGroups(
      {bool isInitialLoad = false, String? groupType}) async {
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

    // Use the passed groupType, or the state's _groupType
    final typeToSearch = groupType ?? _groupType;

    try {
      final results = await apiService.getGroups(
        search: query,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        groupType: typeToSearch,
      );
      print('DEBUG: Total groups fetched: ${results.length}');
      for (var g in results) {
        print('DEBUG: ${g.name} - Type: ${g.groupType}');
      }
      if (mounted) {
        setState(() {
          _groups = results;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(
          
            'Search failed: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup(String groupId) async {
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);

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
            
          'Failed to join group: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    }
  }

  void _showGroupInfoSnackBar(YogaGroup group) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          group.name,
           
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
    // Only show offline groups on map
    final offlineGroups = _displayedGroups
        .where((g) => g.groupType == 'offline')
        .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null
                ? LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  )
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
              markers: offlineGroups
                  .map((group) {
                    if (group.latitude == null || group.longitude == null) {
                      return null;
                    }
                    return Marker(
                      point: LatLng(group.latitude!, group.longitude!),
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () => _showGroupInfoSnackBar(group),
                        child: Tooltip(
                          message: group.name,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  })
                  .whereType<Marker>()
                  .toList(),
            ),
          ],
        ),
        if (offlineGroups.isEmpty && _searchPerformed && !_isLoading)
          Center(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No offline groups found with location',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupCard(YogaGroup group) {
    final isOnline = group.groupType == 'online';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _joinGroup(group.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOnline ? Icons.videocam : Icons.location_on,
                          size: 16,
                          color: isOnline
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOnline
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isOnline ? Icons.link : Icons.location_on_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.displayLocation,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.timingText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      toBeginningOfSentenceCase(group.yogaStyle) ??
                          group.yogaStyle,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(
                      toBeginningOfSentenceCase(
                            group.difficultyLevel.replaceAll('-', ' '),
                          ) ??
                          group.difficultyLevel,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (group.pricePerSession == 0)
                    const Chip(
                      label: Text('Free', style: TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.greenAccent,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Join Group'),
                  onPressed: () => _joinGroup(group.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    final l10n = AppLocalizations.of(context)!;
    if (!_searchPerformed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.enterSearchTerm,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    if (_displayedGroups.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all'
                  ? l10n.noGroupsFoundSearch
                  : 'No ${_selectedFilter} groups found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _displayedGroups.length,
      itemBuilder: (_, index) => _buildGroupCard(_displayedGroups[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchPerformed = false;
                            _groups = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _searchGroups(groupType: _groupType),
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          //   child: SegmentedButton<String>(
          //     segments: const [
          //       ButtonSegment(value: 'all', label: Text('All')),
          //       ButtonSegment(value: 'offline', label: Text('Offline')),
          //       ButtonSegment(value: 'online', label: Text('Online')),
          //     ],
          //     selected: {_groupType},
          //     onSelectionChanged: (newSelection) {
          //       setState(() {
          //         _groupType = newSelection.first;
          //       });
          //       _searchGroups(groupType: _groupType);
          //     },
          //     style: SegmentedButton.styleFrom(
          //       visualDensity: VisualDensity.compact,
          //     ),
          //   ),
          // ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Groups'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = 'all';
                      // Switch to list if map was selected and filter is online
                      if (_isMapView && _isMapDisabled) {
                        _isMapView = false;
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, size: 16),
                      SizedBox(width: 4),
                      Text('Online'),
                    ],
                  ),
                  selected: _selectedFilter == 'online',
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = 'online';
                      // Force list view for online filter
                      _isMapView = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 16),
                      SizedBox(width: 4),
                      Text('Offline'),
                    ],
                  ),
                  selected: _selectedFilter == 'offline',
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = 'offline';
                    });
                  },
                ),
              ],
            ),
          ),

          // Map/List Toggle - Disabled for online filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  
                    value: false,
                  icon: const Icon(Icons.list),
                  label: Text(l10n.list),
                ),
                ButtonSegment(
                  
                    value: true,
                  icon: const Icon(Icons.map),
                  label: Text(l10n.map),
                  enabled: !_isMapDisabled,
                ),
              ],
              selected: {_isMapView},
              onSelectionChanged: _isMapDisabled
                  ? null
                  : (newSelection) {
                      setState(() {
                        _isMapView = newSelection.first;
                      });
                    },
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(),

          Expanded(child: _isMapView ? _buildMapView() : _buildListView()),
        ],
      ),
    );
  }
}