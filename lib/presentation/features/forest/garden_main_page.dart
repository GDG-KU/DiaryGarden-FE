import 'package:diary_garden/core/config/api_config.dart';
import 'package:diary_garden/core/storage/token_storage.dart';
import 'package:diary_garden/core/storage/tree_position_storage.dart';
import 'package:diary_garden/data/datasource/diary_api_client.dart';
import 'package:diary_garden/data/datasource/forest_api_client.dart';
import 'package:diary_garden/data/models/remote_diary_entry.dart';
import 'package:diary_garden/data/models/tree_position.dart';
import 'package:diary_garden/core/utils/tree_vector_util.dart';
import 'package:diary_garden/core/utils/week_calculator.dart';
import 'package:diary_garden/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Represents a tree for a specific week, aggregated from multiple diaries
class WeeklyTree {
  const WeeklyTree({
    required this.weekId,
    required this.weekLabel,
    required this.diaries,
    required this.averageEmotionData,
  });

  final String weekId; // e.g., "week_2025_12_1"
  final String weekLabel; // e.g., "12월 1주차"
  final List<RemoteDiaryEntry> diaries;
  final List<Map<String, dynamic>> averageEmotionData;
}

/// View mode for garden: month (current) or year (12 month grid)
enum GardenViewMode { month, year }

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
  List<WeeklyTree> _weeklyTrees = [];
  Map<String, TreePosition> _positions = {};
  Set<String> _dirtyPositions = {};
  late DateTime _selectedMonth;
  GardenViewMode _viewMode = GardenViewMode.month;
  Map<int, int> _yearTreeCounts = {}; // month -> tree count
  String get _gardenLevel => '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
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

    // Capture current garden level to prevent changes during sync loop
    final currentGardenLevel = _gardenLevel;

    debugPrint('🔄 Syncing ${_dirtyPositions.length} dirty positions for $currentGardenLevel...');

    final successfulSyncs = <String>{};

    for (final treeId in _dirtyPositions) {
      final position = _positions[treeId];
      if (position == null) {
        successfulSyncs.add(treeId); // Remove if not found
        continue;
      }

      try {
        debugPrint('📤 Syncing tree $treeId at (${position.positionX.toStringAsFixed(3)}, ${position.positionY.toStringAsFixed(3)})');
        await _forestApiClient.updateTreePosition(
          authToken: token,
          gardenLevel: currentGardenLevel, // Use captured level
          treeId: treeId,
          positionX: position.positionX,
          positionY: position.positionY,
        );
        debugPrint('✅ Synced position for tree $treeId');
        successfulSyncs.add(treeId);
      } catch (e) {
        debugPrint('❌ Failed to sync position for tree $treeId: $e');
      }
    }

    if (mounted) {
      setState(() {
        _dirtyPositions.removeWhere((id) => successfulSyncs.contains(id));
      });
    }
    
    if (_dirtyPositions.isNotEmpty) {
      debugPrint('⚠️ ${_dirtyPositions.length} positions failed to sync');
    } else {
      debugPrint('✅ Position sync complete for $currentGardenLevel');
    }
  }

  Future<void> _loadData() async {
    // Sync dirty positions is now handled in _changeMonth before state change
    // await _syncDirtyPositions(); 

    
    setState(() => _loading = true);
    
    final token = await TokenStorage.readToken() ?? ApiConfig.maybeAuthToken;
    setState(() => _authToken = token);

    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Load diaries for selected month
      // Expand range by +/- 7 days to handle weeks overlapping month boundaries
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1).subtract(const Duration(days: 7));
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).add(const Duration(days: 7));

      debugPrint('🌳 Loading garden data for $_gardenLevel ($startDate to $endDate)');

      final diaries = await _diaryApiClient.fetchDiaries(
        authToken: token,
        writtenAfter: startDate,
        writtenBefore: endDate,
      );

      debugPrint('📚 Loaded ${diaries.length} diaries for $_gardenLevel');

      // Group diaries by week and create WeeklyTree objects
      final weeklyTrees = _generateWeeklyTrees(diaries);
      debugPrint('🌲 Generated ${weeklyTrees.length} weekly trees');

      // Load tree positions from cache first
      final cachedPositions = await TreePositionStorage.loadPositions(_gardenLevel);
      final positionMap = {for (var p in cachedPositions) p.treeId: p};
      debugPrint('📂 Loaded ${cachedPositions.length} cached positions for $_gardenLevel');

      try {
        final serverPositions = await _forestApiClient.fetchTreePositions(
          authToken: token,
          gardenLevel: _gardenLevel,
        );
        debugPrint('☁️ Loaded ${serverPositions.length} positions from server for $_gardenLevel');
        
        // Update cache with server data, BUT respect local dirty state
        final mergedPositions = <TreePosition>[];
        
        for (var serverPos in serverPositions) {
          if (_dirtyPositions.contains(serverPos.treeId)) {
            // Keep local dirty version
            if (positionMap.containsKey(serverPos.treeId)) {
              mergedPositions.add(positionMap[serverPos.treeId]!);
            } else {
              mergedPositions.add(serverPos);
            }
          } else {
            // Use server version
            mergedPositions.add(serverPos);
            positionMap[serverPos.treeId] = serverPos;
          }
        }
        
        await TreePositionStorage.savePositions(_gardenLevel, mergedPositions);
        
        debugPrint('✅ Final position count: ${positionMap.length}');
      } catch (e) {
        debugPrint('⚠️ Failed to load positions from server, using cache: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버에서 나무 위치를 불러오는데 실패했습니다: $e')),
          );
        }
      }

      setState(() {
        _weeklyTrees = weeklyTrees;
        _positions = positionMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load garden data: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  List<WeeklyTree> _generateWeeklyTrees(List<RemoteDiaryEntry> diaries) {
    // Group diaries by weekId
    final Map<String, List<RemoteDiaryEntry>> diariesByWeek = {};
    final Map<String, WeekInfo> weekInfoMap = {};

    for (final diary in diaries) {
      final weekInfo = WeekCalculator.getWeekInfo(diary.writtenDate);
      
      // STRICT FILTER: Only include weeks that belong to the currently selected month
      if (weekInfo.year != _selectedMonth.year || weekInfo.month != _selectedMonth.month) {
        continue;
      }

      final weekId = 'week_${weekInfo.weekId}'; // e.g., week_2025_12_1
      
      if (!diariesByWeek.containsKey(weekId)) {
        diariesByWeek[weekId] = [];
        weekInfoMap[weekId] = weekInfo;
      }
      diariesByWeek[weekId]!.add(diary);
    }

    // Create WeeklyTree objects
    final trees = <WeeklyTree>[];
    for (final entry in diariesByWeek.entries) {
      final weekId = entry.key;
      final weekDiaries = entry.value;
      final weekInfo = weekInfoMap[weekId]!;

      // Calculate average emotion
      // TODO: Parse actual emotion data from content if available, or use placeholder
      // For now, we'll assume a default emotion or try to parse if structure allows
      final emotionData = _generateEmotionData(weekDiaries);

      trees.add(WeeklyTree(
        weekId: weekId,
        weekLabel: weekInfo.displayLabel,
        diaries: weekDiaries,
        averageEmotionData: emotionData,
      ));
    }
    
    // Sort by weekId to ensure consistent order
    trees.sort((a, b) => a.weekId.compareTo(b.weekId));

    return trees;
  }

  List<Map<String, dynamic>> _generateEmotionData(List<RemoteDiaryEntry> diaries) {
    // Map each diary to an emotion entry using server-provided emotion data
    return diaries.map((diary) {
      // Use the dominant emotion and its score from the server
      // Fallback to 'default' if emotion data is empty or missing
      final emotion = diary.dominantEmotion.isNotEmpty 
          ? diary.dominantEmotion 
          : 'default';
      
      final double score;
      if (diary.emotionScores.isEmpty) {
        // No emotion data available, use default
        score = 1.0;
      } else if (diary.emotionScores.containsKey(emotion)) {
        // Use the score for the dominant emotion
        score = diary.emotionScores[emotion]!;
      } else {
        // Dominant emotion not in scores, use default
        score = 1.0;
      }
      
      return {
        'emotion': emotion,
        'score': score > 0 ? score : 1.0, // Ensure at least 1.0 for visual
      };
    }).toList();
  }

  Future<void> _updateTreePosition(String treeId, double x, double y) async {
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

    // Save to cache immediately
    try {
      await TreePositionStorage.updatePosition(position);
      debugPrint('💾 Cached position for tree $treeId at (${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})');
    } catch (e) {
      debugPrint('❌ Failed to cache position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 저장 실패: $e')),
        );
      }
    }
  }

  Future<void> _changeMonth(int delta) async {
    if (_loading) return;
    setState(() => _loading = true);

    // Sync dirty positions BEFORE changing the month/gardenLevel
    await _syncDirtyPositions();

    if (!mounted) return;

    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    setState(() {
      _selectedMonth = newMonth;
    });
    await _loadData();
  }

  void _switchViewMode(GardenViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
    if (mode == GardenViewMode.year) {
      _loadYearData();
    }
  }

  Future<void> _loadYearData() async {
    final token = _authToken;
    if (token == null) return;

    setState(() => _loading = true);

    try {
      // Fetch diaries for the entire year
      final year = _selectedMonth.year;
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year + 1, 1, 1);

      final diaries = await _diaryApiClient.fetchDiaries(
        authToken: token,
        writtenAfter: startDate,
        writtenBefore: endDate,
        limit: 400,
      );

      // Count trees per month (based on weeks)
      final monthCounts = <int, Set<String>>{};
      for (final diary in diaries) {
        final weekInfo = WeekCalculator.getWeekInfo(diary.writtenDate);
        final weekId = 'week_${weekInfo.weekId}';
        monthCounts.putIfAbsent(weekInfo.month, () => {}).add(weekId);
      }

      if (!mounted) return;
      if (mounted && _viewMode == GardenViewMode.year) {
        setState(() {
          _yearTreeCounts = monthCounts.map((k, v) => MapEntry(k, v.length));
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load year data: $e');
      if (!mounted) return;
      if (_viewMode == GardenViewMode.year) {
        setState(() => _loading = false);
      }
  }

  void _navigateToMonth(int month) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, month, 1);
      _viewMode = GardenViewMode.month;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    const offWhite = Color(0xFFFAF6EE);
    final isMonthView = _viewMode == GardenViewMode.month;

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: offWhite,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('나의 숲'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ToggleButtons(
              isSelected: [isMonthView, !isMonthView],
              onPressed: (i) => _switchViewMode(
                i == 0 ? GardenViewMode.month : GardenViewMode.year,
              ),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 32),
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: AppColors.trunk,
              color: AppColors.textSecondary,
              children: const [Text('월'), Text('년')],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : isMonthView
              ? _buildMonthView()
              : _buildYearView(),
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        // Month navigation header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
                tooltip: '이전 달',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${_selectedMonth.year}년 ${_selectedMonth.month}월',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '나무 수: ${_weeklyTrees.length}그루',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
                tooltip: '다음 달',
              ),
            ],
          ),
        ),

        // Interactive forest area
        Expanded(
          child: _ForestCanvas(
            weeklyTrees: _weeklyTrees,
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
    );
  }

  Widget _buildYearView() {
    return Column(
      children: [
        // Year navigation header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year - 1, 1, 1);
                  });
                  _loadYearData();
                },
                tooltip: '이전 년',
              ),
              Expanded(
                child: Text(
                  '${_selectedMonth.year}년',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year + 1, 1, 1);
                  });
                  _loadYearData();
                },
                tooltip: '다음 년',
              ),
            ],
          ),
        ),

        // 12 month grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, index) {
                final month = index + 1;
                final count = _yearTreeCounts[month] ?? 0;
                final hasData = count > 0;
                final intensity = (count / 5).clamp(0.0, 1.0);
                
                return GestureDetector(
                  onTap: () => _navigateToMonth(month),
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasData
                          ? AppColors.leafGreen.withOpacity(0.15 + intensity * 0.4)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasData
                            ? AppColors.leafGreen.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$month월',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.park,
                              size: 20,
                              color: hasData
                                  ? AppColors.leafGreen
                                  : Colors.grey.withOpacity(0.4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$count그루',
                              style: TextStyle(
                                color: hasData
                                    ? AppColors.textSecondary
                                    : Colors.grey.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Bottom hint
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Text(
            '월을 탭하면 해당 월로 이동해요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _ForestCanvas extends StatelessWidget {
  const _ForestCanvas({
    required this.weeklyTrees,
    required this.positions,
    required this.onPositionUpdate,
  });

  final List<WeeklyTree> weeklyTrees;
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
              ...weeklyTrees.asMap().entries.map((entry) {
                final index = entry.key;
                final tree = entry.value;
                final position = positions[tree.weekId];

                // Default position if not set (grid layout)
                final defaultX = ((index % 4) * 0.25 + 0.125);
                final defaultY = ((index ~/ 4) * 0.25 + 0.2).clamp(0.1, 0.8);

                final x = position?.positionX ?? defaultX;
                final y = position?.positionY ?? defaultY;

                return _DraggableTree(
                  key: ValueKey(tree.weekId),
                  tree: tree,
                  initialX: x,
                  initialY: y,
                  canvasWidth: width,
                  canvasHeight: height,
                  onPositionChanged: (newX, newY) {
                    onPositionUpdate(tree.weekId, newX, newY);
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
    required this.tree,
    required this.initialX,
    required this.initialY,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onPositionChanged,
  });

  final WeeklyTree tree;
  final double initialX;
  final double initialY;
  final double canvasWidth;
  final double canvasHeight;
  final Function(double x, double y) onPositionChanged;

  @override
  State<_DraggableTree> createState() => _DraggableTreeState();
}

class _DraggableTreeState extends State<_DraggableTree> {
  // Store absolute position for smoother dragging
  late double _currentLeft;
  late double _currentTop;
  final double _treeSize = 80.0;

  @override
  void initState() {
    super.initState();
    _updatePositionFromWidget();
  }

  @override
  void didUpdateWidget(_DraggableTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialX != widget.initialX || 
        oldWidget.initialY != widget.initialY ||
        oldWidget.canvasWidth != widget.canvasWidth ||
        oldWidget.canvasHeight != widget.canvasHeight) {
      _updatePositionFromWidget();
    }
  }

  void _updatePositionFromWidget() {
    _currentLeft = (widget.initialX * widget.canvasWidth) - (_treeSize / 2);
    _currentTop = (widget.initialY * widget.canvasHeight) - (_treeSize / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentLeft,
      top: _currentTop,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _currentLeft += details.delta.dx;
            _currentTop += details.delta.dy;
          });
        },
        onPanEnd: (details) {
          // Normalize and clamp only when drag ends
          final normalizedX = ((_currentLeft + _treeSize / 2) / widget.canvasWidth).clamp(0.0, 1.0);
          final normalizedY = ((_currentTop + _treeSize / 2) / widget.canvasHeight).clamp(0.0, 1.0);
          
          widget.onPositionChanged(normalizedX, normalizedY);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TreeWidget(size: _treeSize, emotionData: widget.tree.averageEmotionData),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.tree.weekLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeWidget extends StatefulWidget {
  const _TreeWidget({required this.size, required this.emotionData});

  final double size;
  final List<Map<String, dynamic>> emotionData;

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

  @override
  void didUpdateWidget(_TreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emotionData != oldWidget.emotionData) {
      _loadTree();
    }
  }

  Future<void> _loadTree() async {
    try {
      final treeData = await TreeVectorUtil.svgFor(emotionData: widget.emotionData);
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
