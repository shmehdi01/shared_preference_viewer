import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsViewer extends StatefulWidget {
  const SharedPrefsViewer({super.key});

  static Future<dynamic> navigate(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SharedPrefsViewer()),
    );
  }

  @override
  State<SharedPrefsViewer> createState() => _SharedPrefsViewerState();
}

class _SharedPrefsViewerState extends State<SharedPrefsViewer> {
  Map<String, dynamic> _prefs = {};
  Map<String, dynamic> _filtered = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedType;

  final List<String> _typeFilters = [
    'All',
    'String',
    'int',
    'double',
    'bool',
    'List<String>',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final map = <String, dynamic>{};
    for (final key in keys) {
      map[key] = prefs.get(key);
    }
    setState(() {
      _prefs = map;
      _filtered = map;
      _isLoading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      _filtered = Map.fromEntries(
        _prefs.entries.where((e) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              e.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.value.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          final matchesType =
              _selectedType == null ||
              _selectedType == 'All' ||
              _getType(e.value) == _selectedType;

          return matchesSearch && matchesType;
        }),
      );
    });
  }

  String _getType(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List<String>';
    return 'Unknown';
  }

  Color _getTypeColor(dynamic value) {
    if (value is String) return const Color(0xFF4CAF93);
    if (value is int) return const Color(0xFF5B8AF5);
    if (value is double) return const Color(0xFF9B6CF7);
    if (value is bool)
      return value ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
    if (value is List) return const Color(0xFFF5A623);
    return Colors.grey;
  }

  Future<void> _deleteKey(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Key', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$key"?',
          style: const TextStyle(color: Color(0xFFB0B0C8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0C8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF5350)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      _loadPrefs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$key" deleted'),
            backgroundColor: const Color(0xFF2A2A3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete all stored preferences.',
          style: TextStyle(color: Color(0xFFB0B0C8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0C8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xFFEF5350)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _loadPrefs();
    }
  }

  void _copyValue(String key, dynamic value) {
    Clipboard.setData(ClipboardData(text: value.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$key" copied to clipboard'),
        backgroundColor: const Color(0xFF2A2A3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131F),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8AF5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Color(0xFF5B8AF5),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SharedPrefs Viewer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5B8AF5)),
            tooltip: 'Refresh',
            onPressed: _loadPrefs,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Color(0xFFEF5350),
            ),
            tooltip: 'Clear All',
            onPressed: _clearAll,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value: _prefs.length.toString(),
                  color: const Color(0xFF5B8AF5),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Showing',
                  value: _filtered.length.toString(),
                  color: const Color(0xFF4CAF93),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search keys or values...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilter();
              },
            ),
          ),

          // Type Filter Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _typeFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _typeFilters[i];
                final selected = (_selectedType ?? 'All') == t;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedType = t);
                    _applyFilter();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF5B8AF5)
                          : const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5B8AF5)),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _prefs.isEmpty
                              ? 'No preferences stored'
                              : 'No results found',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final key = _filtered.keys.elementAt(i);
                      final value = _filtered[key];
                      final typeColor = _getTypeColor(value);
                      final typeName = _getType(value);

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeName,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              value.toString(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.copy_rounded,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                onPressed: () => _copyValue(key, value),
                                tooltip: 'Copy value',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFEF5350),
                                ),
                                onPressed: () => _deleteKey(key),
                                tooltip: 'Delete',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
