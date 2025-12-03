import 'package:diary_garden/core/config/api_config.dart';
import 'package:diary_garden/core/storage/token_storage.dart';
import 'package:diary_garden/core/storage/tree_position_storage.dart';
import 'package:diary_garden/data/datasource/diary_api_client.dart';
import 'package:diary_garden/data/datasource/forest_api_client.dart';
import 'package:diary_garden/data/models/remote_diary_entry.dart';
import 'package:diary_garden/data/models/tree_position.dart';
import 'package:diary_garden/core/utils/tree_vector_util.dart';
import 'package:diary_garden/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GardenMainPage extends StatefulWidget {
  const GardenMainPage({super.key});

  @override
  State<GardenMainPage> createState() => _GardenMainPageState();
}

class _GardenMainPageState extends State<GardenMainPage> {
  final DiaryApiClient _diaryApiClient = DiaryApiClient();
  final ForestApiClient _forestApiClient = ForestApiClient();

  String? _authToken;
  bool _loading = true;
  List<RemoteDiaryEntry> _diaries = [];
  Map<String, TreePosition> _positions = {}; // treeId -> position
  Set<String> _dirtyPositions = {}; // Track which positions changed
  late String _gardenLevel;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _gardenLevel = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadData();
  }

  @override
  void dispose() {
    // Sync all dirty positions before disposing
    _syncDirtyPositions();
    super.dispose();
  }

  Future<void> _syncDirtyPositions() async {
    if (_dirtyPositions.isEmpty) return;
    
    final token = _authToken;
    if (token == null) return;

    debugPrint('🔄 Syncing ${_dirtyPositions.length} dirty positions...');

    for (final treeId in _dirtyPositions) {
      final position = _positions[treeId];
      if (position == null) continue;

      try {
        await _forestApiClient.updateTreePosition(
          authToken: token,
          gardenLevel: _gardenLevel,
          treeId: treeId,
          positionX: position.positionX,
          positionY: position.positionY,
        );
        debugPrint('✅ Synced position for tree $treeId');
      } catch (e) {
        debugPrint('❌ Failed to sync position for tree $treeId: $e');
      }
    }

    _dirtyPositions.clear();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    final token = await TokenStorage.readToken() ?? ApiConfig.maybeAuthToken;
    setState(() => _authToken = token);

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Load diaries for current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final diaries = await _diaryApiClient.fetchDiaries(
        authToken: token,
        writtenAfter: startDate,
        writtenBefore: endDate,
      );

      // Load tree positions from cache first, then server
      final cachedPositions = await TreePositionStorage.loadPositions(_gardenLevel);
      final positionMap = {for (var p in cachedPositions) p.treeId: p};

      try {
        final serverPositions = await _forestApiClient.fetchTreePositions(
          authToken: token,
          gardenLevel: _gardenLevel,
        );
        // Update cache with server data
        await TreePositionStorage.savePositions(_gardenLevel, serverPositions);
        // Merge server positions
        for (var p in serverPositions) {
          positionMap[p.treeId] = p;
        }
      } catch (e) {
        debugPrint('Failed to load positions from server, using cache: $e');
      }

      setState(() {
        _diaries = diaries;
        _positions = positionMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load garden data: $e');
      setState(() => _loading = false);
    }
  }

  void _updateTreePosition(String treeId, double x, double y) {
    final position = TreePosition(
      gardenLevel: _gardenLevel,
      treeId: treeId,
      positionX: x.clamp(0.0, 1.0),
      positionY: y.clamp(0.0, 1.0),
      updatedAt: DateTime.now(),
    );

    // Update local state and mark as dirty
    setState(() {
      _positions[treeId] = position;
      _dirtyPositions.add(treeId);
    });

    // Save to cache only (no server sync yet)
    TreePositionStorage.updatePosition(position);
  }

  @override
  Widget build(BuildContext context) {
    const offWhite = Color(0xFFFAF6EE);
    const lawn = Color(0xFF8BC68B);

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: offWhite,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('나의 숲'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_gardenLevel',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '나무 수: ${_diaries.length}그루',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive forest area
                Expanded(
                  child: _ForestCanvas(
                    diaries: _diaries,
                    positions: _positions,
                    onPositionUpdate: _updateTreePosition,
                  ),
                ),

                // Bottom hint
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 36),
                  child: Text(
                    '나무를 드래그하여 자유롭게 배치할 수 있어요 🌳',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ForestCanvas extends StatelessWidget {
  const _ForestCanvas({
    required this.diaries,
    required this.positions,
    required this.onPositionUpdate,
  });

  final List<RemoteDiaryEntry> diaries;
  final Map<String, TreePosition> positions;
  final Function(String treeId, double x, double y) onPositionUpdate;

  @override
  Widget build(BuildContext context) {
    const lawn = Color(0xFF8BC68B);

    return Container(
      color: lawn.withOpacity(0.3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFAF6EE),
                        lawn.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),

              // Trees
              ...diaries.asMap().entries.map((entry) {
                final index = entry.key;
                final diary = entry.value;
                final position = positions[diary.treeId];

                // Default position if not set (grid layout)
                final defaultX = ((index % 4) * 0.25 + 0.125);
                final defaultY = ((index ~/ 4) * 0.25 + 0.2).clamp(0.1, 0.8);

                final x = position?.positionX ?? defaultX;
                final y = position?.positionY ?? defaultY;

                return _DraggableTree(
                  key: ValueKey(diary.id), // Use diary.id for uniqueness
                  diary: diary,
                  initialX: x,
                  initialY: y,
                  canvasWidth: width,
                  canvasHeight: height,
                  onPositionChanged: (newX, newY) {
                    onPositionUpdate(diary.treeId, newX, newY);
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _DraggableTree extends StatefulWidget {
  const _DraggableTree({
    super.key,
    required this.diary,
    required this.initialX,
    required this.initialY,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onPositionChanged,
  });

  final RemoteDiaryEntry diary;
  final double initialX;
  final double initialY;
  final double canvasWidth;
  final double canvasHeight;
  final Function(double x, double y) onPositionChanged;

  @override
  State<_DraggableTree> createState() => _DraggableTreeState();
}

class _DraggableTreeState extends State<_DraggableTree> {
  late double _normalizedX;
  late double _normalizedY;

  @override
  void initState() {
    super.initState();
    _normalizedX = widget.initialX;
    _normalizedY = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    // Convert normalized coordinates to absolute positions
    const treeSize = 80.0;
    final left = (_normalizedX * widget.canvasWidth) - (treeSize / 2);
    final top = (_normalizedY * widget.canvasHeight) - (treeSize / 2);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Update position based on delta, working with CURRENT state
          setState(() {
            // Calculate new absolute positions from current state
            final currentLeft = (_normalizedX * widget.canvasWidth) - (treeSize / 2);
            final currentTop = (_normalizedY * widget.canvasHeight) - (treeSize / 2);
            
            final newLeft = currentLeft + details.delta.dx;
            final newTop = currentTop + details.delta.dy;

            // Convert back to normalized coordinates
            _normalizedX = ((newLeft + treeSize / 2) / widget.canvasWidth).clamp(0.0, 1.0);
            _normalizedY = ((newTop + treeSize / 2) / widget.canvasHeight).clamp(0.0, 1.0);
          });
        },
        onPanEnd: (details) {
          // Save position when drag ends
          widget.onPositionChanged(_normalizedX, _normalizedY);
        },
        child: _TreeWidget(size: treeSize, diary: widget.diary),
      ),
    );
  }
}

class _TreeWidget extends StatefulWidget {
  const _TreeWidget({required this.size, required this.diary});

  final double size;
  final RemoteDiaryEntry diary;

  @override
  State<_TreeWidget> createState() => _TreeWidgetState();
}

class _TreeWidgetState extends State<_TreeWidget> {
  TreeVectorData? _treeData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    try {
      // Parse diary content to extract emotion data
      final content = widget.diary.content;
      
      // For now, use a default emotion until we have proper emotion analysis
      // TODO: Parse content or fetch emotion data from API
      final emotionData = [
        {
          'emotion': 'default',
          'score': 0.8,
        }
      ];

      final treeData = await TreeVectorUtil.svgFor(emotionData: emotionData);
      if (mounted) {
        setState(() {
          _treeData = treeData;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load tree: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.green.withOpacity(0.5),
          ),
        ),
      );
    }

    if (_treeData == null) {
      // Fallback icon if tree data failed to load
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFF93E6AA),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.park,
          color: Colors.white,
          size: 40,
        ),
      );
    }

    // Render actual tree with TreeVectorUtil
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: _treeData!.toPicture(width: widget.size),
      ),
    );
  }
}
