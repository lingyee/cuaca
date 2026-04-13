import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/place.dart';
import '../services/photon_service.dart';
import '../providers/weather_provider.dart';

class PlaceSearchBar extends ConsumerStatefulWidget {
  final VoidCallback? onPlaceSelected;

  const PlaceSearchBar({super.key, this.onPlaceSelected});

  @override
  ConsumerState<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends ConsumerState<PlaceSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _nominatim = PhotonService();
  Timer? _debounce;
  List<Place> _suggestions = [];
  bool _loading = false;
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    List<Place> results = [];
    try {
      results = await _nominatim.search(query);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loading = false;
    });
    if (results.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _selectPlace(Place place) {
    _controller.text = place.shortName;
    _removeOverlay();
    setState(() => _suggestions = []);
    _focusNode.unfocus();
    ref.read(selectedPlaceProvider.notifier).set(place);
    widget.onPlaceSelected?.call();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: _layerLink.leaderSize?.width ?? 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (_, i) {
                final p = _suggestions[i];
                return ListTile(
                  leading: const Icon(Icons.location_on, size: 20),
                  title: Text(p.shortName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(p.displayName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  onTap: () => _selectPlace(p),
                );
              },
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: 'Search place, mall, park…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _removeOverlay();
                        setState(() => _suggestions = []);
                        ref.read(selectedPlaceProvider.notifier).set(null);
                      },
                    )
                  : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }
}
