import 'package:diary_garden/core/config/api_config.dart';
import 'package:diary_garden/core/storage/diary_storage.dart';
import 'package:diary_garden/core/storage/pending_diary_storage.dart';
import 'package:diary_garden/core/storage/token_storage.dart';
import 'package:diary_garden/core/theme/app_colors.dart';
import 'package:diary_garden/core/utils/tree_vector_util.dart';
import 'package:diary_garden/core/utils/week_calculator.dart';
import 'package:diary_garden/data/datasource/diary_api_client.dart';
import 'package:diary_garden/data/models/diary_entry.dart';
import 'package:diary_garden/data/models/remote_diary_entry.dart';
import 'package:diary_garden/data/services/diary_sync_service.dart';
import 'package:diary_garden/presentation/features/diary/diary_read_page.dart';
import 'package:diary_garden/presentation/features/diary/diary_write_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final DiaryApiClient _diaryApiClient;
  late final DiarySyncService _syncService;
  late final PageController _pageController;
  late WeekInfo _currentWeek;
  late List<_DayStatusModel> _dayStatuses;
  List<DiaryEntry> _weekDiaries = [];
  String? _authToken;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _diaryApiClient = DiaryApiClient();
    _syncService = DiarySyncService(apiClient: _diaryApiClient);
    _pageController = PageController(initialPage: 1); // Start at middle (current week)
    _currentWeek = WeekCalculator.getCurrentWeek();
    _dayStatuses = _generateWeekStatuses(_currentWeek);
    _loadAuthToken();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthToken() async {
    final stored = await TokenStorage.readToken();
    setState(() {
      _authToken = stored ?? ApiConfig.maybeAuthToken;
    });
    await _loadRecentDiaries();
    await _loadWeekDiaries(); // Load diaries for current week
    await _syncPendingDiaries(); // 앱 시작 시 대기 중인 일기 동기화
  }

  Future<void> _syncPendingDiaries() async {
    final token = _authToken;
    if (token == null) return;

    final pendingCount = await PendingDiaryStorage.getPendingCount();
    if (pendingCount == 0) return;

    setState(() => _pendingCount = pendingCount);

    final result = await _syncService.syncPendingDiaries(token);

    if (!mounted) return;

    final newPendingCount = await PendingDiaryStorage.getPendingCount();
    setState(() => _pendingCount = newPendingCount);

    if (result.allSuccess) {
      _showSnackBar('오프라인 일기 ${result.successCount}개가 동기화되었습니다! 🌱');
      await _loadRecentDiaries();
    } else if (result.hasFailures) {
      _showSnackBar('일부 일기 동기화 실패 (${result.failCount}개)');
    }
  }

  List<_DayStatusModel> _generateWeekStatuses(WeekInfo week) {
    final weekDates = WeekCalculator.getWeekDates(week);
    return List.generate(_weekdayLabels.length, (index) {
      final date = weekDates[index];
      final treeId = _treeIdForDate(date);
      return _DayStatusModel(
        label: _weekdayLabels[index],
        date: date,
        treeId: treeId,
      );
    });
  }

  Future<void> _loadRecentDiaries() async {
    final token = _authToken;
    if (token == null) return;

    // 먼저 pending 일기들의 날짜를 로드
    final pendingDiaries = await PendingDiaryStorage.getPendingDiaries();
    final pendingDates = pendingDiaries.map((d) => d.writtenDate).toSet();

    try {
      // Fetch all diaries (no limit, no updatedAfter for comprehensive fetch)
      final diaries = await _diaryApiClient.fetchDiaries(
        authToken: token,
        limit: 0, // 0 means fetch all
      );

      // 로컬 캐시 업데이트
      await DiaryStorage.updateFromEntries(diaries, fullSync: true);

      debugPrint('📅 Loaded ${diaries.length} diaries from API');
      for (final diary in diaries) {
        debugPrint('  - Diary: ${diary.writtenDate}');
      }
      
      // Get current week date range
      final weekDates = WeekCalculator.getWeekDates(_currentWeek);
      final currentWeekStart = weekDates.first;
      final currentWeekEnd = weekDates.last;
      
      debugPrint('📅 Current week: $currentWeekStart to $currentWeekEnd');
      debugPrint('📅 Current week statuses:');
      for (final status in _dayStatuses) {
        debugPrint('  - ${status.date}: has diary = ${status.hasDiary}');
      }

      if (!mounted) return;
      setState(() {
        _dayStatuses = _dayStatuses.map((status) {
          final match = _findDiaryForDate(diaries, status.date);
          final isPending = pendingDates.any(
            (d) => DateUtils.isSameDay(d, status.date),
          );
          if (match != null) {
            debugPrint('✅ Matched diary ${match.id.substring(0, 8)} to date ${status.date}');
            return status.copyWith(diaryId: match.id, hasPendingDiary: false);
          }
          if (isPending) {
            return status.copyWith(hasPendingDiary: true);
          }
          return status;
        }).toList();
        _pendingCount = pendingDiaries.length;
      });
    } catch (error) {
      debugPrint('Failed to load diaries: $error');
      // API 실패 시에도 pending 상태는 표시
      if (mounted) {
        setState(() {
          _dayStatuses = _dayStatuses.map((status) {
            final isPending = pendingDates.any(
              (d) => DateUtils.isSameDay(d, status.date),
            );
            if (isPending) {
              return status.copyWith(hasPendingDiary: true);
            }
            return status;
          }).toList();
          _pendingCount = pendingDiaries.length;
        });
      }
    }
  }

  /// Load diaries for the current week and convert to DiaryEntry format
  Future<void> _loadWeekDiaries() async {
    final token = _authToken;
    if (token == null) return;

    try {
      // Fetch diaries for the current week's date range
      final weekDates = WeekCalculator.getWeekDates(_currentWeek);
      final startDate = weekDates.first;
      final endDate = weekDates.last;

      // Get all diaries in this date range
      final allDiaries = await _diaryApiClient.fetchDiaries(
        authToken: token,
        limit: 100,
      );

      // Filter for current week and convert to DiaryEntry
      final weekDiaries = <DiaryEntry>[];
      for (final remoteDiary in allDiaries) {
        final diaryDate = remoteDiary.writtenDate;
        if (!diaryDate.isBefore(startDate) && !diaryDate.isAfter(endDate)) {
          weekDiaries.add(_toDiaryEntry(remoteDiary));
        }
      }

      if (mounted) {
        setState(() {
          _weekDiaries = weekDiaries;
        });
      }
    } catch (error) {
      debugPrint('Failed to load week diaries: $error');
      if (mounted) {
        setState(() {
          _weekDiaries = [];
        });
      }
    }
  }

  /// Handle page view changes when user swipes between weeks
  Future<void> _onPageChanged(int index) async {
    // index: 0 = previous week, 1 = current week, 2 = next week
    WeekInfo newWeek;
    switch (index) {
      case 0:
        newWeek = WeekCalculator.getPreviousWeek(_currentWeek);
        break;
      case 2:
        newWeek = WeekCalculator.getNextWeek(_currentWeek);
        break;
      default:
        return; // Stay on current week (index 1)
    }

    setState(() {
      _currentWeek = newWeek;
      _dayStatuses = _generateWeekStatuses(_currentWeek);
    });

    // Load diaries for the new week
    await _loadWeekDiaries();
    await _loadRecentDiaries(); // Update day statuses with diary IDs

    // Reset to middle page for infinite scrolling effect
    if (mounted && _pageController.hasClients) {
      _pageController.jumpToPage(1);
    }
  }

  RemoteDiaryEntry? _findDiaryForDate(
    List<RemoteDiaryEntry> diaries,
    DateTime date,
  ) {
    for (final entry in diaries) {
      if (DateUtils.isSameDay(entry.writtenDate, date)) {
        return entry;
      }
    }
    return null;
  }

  String _treeIdForDate(DateTime date) =>
      'tree-${DateFormat('yyyyMMdd').format(date)}';

  Future<void> _openWritePage() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DiaryWritePage(
          onSubmit: (date, title, body) => _submitDiary(date, title, body),
        ),
      ),
    );
    if (saved == true) {
      await _loadRecentDiaries();
    }
  }

  Future<RemoteDiaryEntry> _submitDiary(
    DateTime date,
    String title,
    String body,
  ) async {
    final token = _authToken;
    if (token == null) {
      throw const DiaryApiException('API 토큰이 설정되어 있지 않습니다.');
    }

    // 하루 1개 제한 체크 (로컬 캐시 + pending 모두 확인)
    final alreadyExists = await DiaryStorage.hasDiaryForDate(date);
    final hasPending = await PendingDiaryStorage.hasPendingForDate(date);
    if (alreadyExists || hasPending) {
      throw const DiaryApiException('해당 날짜에 이미 일기가 작성되어 있습니다.');
    }

    try {
      final entry = await _diaryApiClient.createDiary(
        authToken: token,
        title: title,
        content: body,
        writtenDate: date,
      );

      // 작성 성공 시 로컬 캐시에 즉시 반영
      await DiaryStorage.addWrittenDate(date);

      if (mounted) {
        setState(() {
          _dayStatuses = _dayStatuses.map((status) {
            if (DateUtils.isSameDay(status.date, date)) {
              return status.copyWith(diaryId: entry.id);
            }
            return status;
          }).toList();
        });
      }
      return entry;
    } catch (e) {
      // 네트워크 오류 등으로 API 실패 시 로컬에 저장
      debugPrint('API 실패, 로컬에 저장: $e');

      final localId =
          'pending_${date.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';
      final pendingDiary = PendingDiary(
        localId: localId,
        title: title,
        content: body,
        writtenDate: date,
        createdAt: DateTime.now(),
      );

      await PendingDiaryStorage.addPendingDiary(pendingDiary);

      if (mounted) {
        setState(() {
          _pendingCount++;
          // pending 상태로 UI 업데이트 (diaryId는 null이지만 hasPending으로 표시)
          _dayStatuses = _dayStatuses.map((status) {
            if (DateUtils.isSameDay(status.date, date)) {
              return status.copyWith(hasPendingDiary: true);
            }
            return status;
          }).toList();
        });
        _showSnackBar('오프라인에 저장되었습니다. 네트워크 연결 시 자동 동기화됩니다.');
      }

      // pending으로 저장되었음을 나타내는 더미 entry 반환
      return RemoteDiaryEntry(
        id: localId,
        userId: '',
        treeId: '',
        content: '$title\n\n$body',
        writtenDate: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> _handleDayTap(_DayStatusModel status) async {
    // pending 상태인 경우 로컬에서 데이터 표시
    if (status.hasPendingDiary && status.diaryId == null) {
      final pendingDiaries = await PendingDiaryStorage.getPendingDiaries();
      final pending = pendingDiaries.firstWhere(
        (d) => DateUtils.isSameDay(d.writtenDate, status.date),
        orElse: () => PendingDiary(
          localId: '',
          title: '',
          content: '',
          writtenDate: status.date,
          createdAt: DateTime.now(),
        ),
      );

      if (pending.localId.isEmpty) {
        _showSnackBar('저장된 일기를 찾을 수 없습니다.');
        return;
      }

      final diaryEntry = DiaryEntry(
        id: pending.localId,
        title: pending.title.isEmpty ? '오늘 하루' : pending.title,
        content: pending.content,
        date: pending.writtenDate,
        emotionScores: const {'default': 1.0},
        dominantEmotion: 'default',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DiaryReadPage(entries: [diaryEntry])),
      );
      return;
    }

    if (!status.hasDiary || status.diaryId == null) {
      _showSnackBar('아직 작성된 일기가 없어요.');
      return;
    }
    final token = _authToken;
    if (token == null) {
      _showSnackBar('API 토큰이 필요합니다.');
      return;
    }

    debugPrint('Fetching diary with id: ${status.diaryId}');

    // 로딩 다이얼로그 표시 (await 없이)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      final entry = await _diaryApiClient.fetchDiary(
        id: status.diaryId!,
        authToken: token,
      );
      debugPrint('Fetched diary: ${entry.id}');
      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      final diaryEntry = _toDiaryEntry(entry);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DiaryReadPage(entries: [diaryEntry])),
      );
    } catch (error) {
      debugPrint('Failed to fetch diary: $error');
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showSnackBar('일기를 불러오지 못했습니다.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _composeContent(String title, String body) {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) return trimmedTitle;
    if (trimmedTitle.isEmpty) return trimmedBody;
    return '$trimmedTitle\n\n$trimmedBody';
  }

  DiaryEntry _toDiaryEntry(RemoteDiaryEntry entry) {
    final parsed = splitDiaryContent(entry.content);
    return DiaryEntry(
      id: entry.id,
      title: parsed.title.isEmpty ? '오늘 하루' : parsed.title,
      content: parsed.body.isEmpty ? parsed.title : parsed.body,
      date: entry.writtenDate,
      emotionScores: const {'default': 1.0},
      dominantEmotion: 'default',
    );
  }

  void _openCalendar() {
    Navigator.of(context).pushNamed('/home');
  }

  void _handleMenuTap() {
    _showSnackBar('메뉴 화면은 준비 중입니다.');
  }

  void _handleProfileTap() {
    showDialog<void>(
      context: context,
      builder: (_) => ProfileDialog(onLogout: _handleLogout),
    );
  }

  Future<void> _handleLogout() async {
    await TokenStorage.clearToken();
    await DiaryStorage.clear();
    await PendingDiaryStorage.clear(); // 로그아웃 시 pending 일기도 삭제
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _MainScrollView(
                pageController: _pageController,
                currentWeek: _currentWeek,
                statuses: _dayStatuses,
                weekDiaries: _weekDiaries,
                onPageChanged: _onPageChanged,
                onDayTap: _handleDayTap,
                onMenuTap: _handleMenuTap,
                onCalendarTap: _openCalendar,
                onProfileTap: _handleProfileTap,
              ),
            ),
            _FloatingWriteButton(onPressed: _openWritePage),
          ],
        ),
      ),
    );
  }
}

class _MainScrollView extends StatelessWidget {
  const _MainScrollView({
    required this.pageController,
    required this.currentWeek,
    required this.statuses,
    required this.weekDiaries,
    required this.onPageChanged,
    required this.onDayTap,
    required this.onMenuTap,
    required this.onCalendarTap,
    required this.onProfileTap,
  });

  final PageController pageController;
  final WeekInfo currentWeek;
  final List<_DayStatusModel> statuses;
  final List<DiaryEntry> weekDiaries;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<_DayStatusModel> onDayTap;
  final VoidCallback onMenuTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _TopActionsRow(
            onMenuTap: onMenuTap,
            onCalendarTap: onCalendarTap,
            onProfileTap: onProfileTap,
          ),
          const SizedBox(height: 32),
          // Week header (e.g., "12월 3주차")
          _WeekHeader(weekInfo: currentWeek),
          const SizedBox(height: 16),
          const _DayHeaderRow(),
          const SizedBox(height: 10),
          // PageView for week navigation
          SizedBox(
            height: 50, // Height for day bubbles
            child: PageView(
              controller: pageController,
              onPageChanged: onPageChanged,
              children: [
                _DayStatusRow(statuses: statuses, onTap: onDayTap), // Prev (placeholder)
                _DayStatusRow(statuses: statuses, onTap: onDayTap), // Current
                _DayStatusRow(statuses: statuses, onTap: onDayTap), // Next (placeholder)
              ],
            ),
          ),
          const SizedBox(height: 116),
          _TreeIllustration(
            weekDiaries: weekDiaries,
          ),
        ],
      ),
    );
  }
}

class _TopActionsRow extends StatelessWidget {
  const _TopActionsRow({
    required this.onMenuTap,
    required this.onCalendarTap,
    required this.onProfileTap,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _TopIconButton(
            assetPath: 'assets/images/Menu.svg',
            semanticLabel: 'menu_button',
            onTap: onMenuTap,
          ),
          const Spacer(),
          _TopIconButton(
            assetPath: 'assets/images/calendar.svg',
            semanticLabel: 'calendar_button',
            onTap: onCalendarTap,
          ),
          const SizedBox(width: 12),
          _TopIconButton(
            assetPath: 'assets/images/Profile.png',
            semanticLabel: 'profile_button',
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.assetPath,
    this.semanticLabel,
    this.onTap,
  });

  final String assetPath;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = assetPath.toLowerCase().split('.').last;
    final imageWidget = ext == 'svg'
        ? _SvgAssetPicture(
            assetPath: assetPath,
            width: 28,
            height: 28,
            semanticLabel: semanticLabel,
            fallback: Icon(
              Icons.image_outlined,
              color: Colors.black54,
              size: 24,
            ),
          )
        : Image.asset(assetPath, width: 28, height: 28, fit: BoxFit.contain);

    Widget child = SizedBox(
      width: 48,
      height: 48,
      child: Center(child: imageWidget),
    );
    child = Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: child,
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: child,
      onTap: onTap,
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.weekInfo});

  final WeekInfo weekInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Text(
          weekInfo.displayLabel, // e.g., "12월 3주차"
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow();

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black.withValues(alpha: 0.75);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final label in _weekdayLabels)
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayStatusRow extends StatelessWidget {
  const _DayStatusRow({required this.statuses, required this.onTap});

  final List<_DayStatusModel> statuses;
  final ValueChanged<_DayStatusModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final status in statuses)
            _DayBubble(status: status, onTap: () => onTap(status)),
        ],
      ),
    );
  }
}

class _DayBubble extends StatelessWidget {
  const _DayBubble({required this.status, required this.onTap});

  final _DayStatusModel status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        label: status.hasDiary
            ? 'written_day_${status.label}'
            : 'unwritten_day_${status.label}',
        button: true,
        child: SizedBox(
          width: 40,
          height: 40,
          child: status.hasPendingDiary && status.diaryId == null
              ? _buildPendingDayLeaf()
              : status.hasDiary
              ? _buildWrittenDayLeaf()
              : _buildUnwrittenDayCircle(),
        ),
      ),
    );
  }

  Widget _buildPendingDayLeaf() {
    // pending 상태: 반투명 이파리 + 점선 테두리
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.leafGreen.withOpacity(0.4),
        border: Border.all(
          color: AppColors.leafGreen,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: const Icon(
        Icons.cloud_upload_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildWrittenDayLeaf() {
    return Image.asset(
      'assets/images/writtenDay.png',
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stack) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF7AB87A),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.eco, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildUnwrittenDayCircle() {
    return Image.asset(
      'assets/images/unWrittenDay.png',
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stack) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 1.5),
        ),
      ),
    );
  }
}

class _DayStatusModel {
  const _DayStatusModel({
    required this.label,
    required this.date,
    required this.treeId,
    this.diaryId,
    this.hasPendingDiary = false,
  });

  final String label;
  final DateTime date;
  final String treeId;
  final String? diaryId;
  final bool hasPendingDiary;

  bool get hasDiary => diaryId != null || hasPendingDiary;

  _DayStatusModel copyWith({String? diaryId, bool? hasPendingDiary}) {
    return _DayStatusModel(
      label: label,
      date: date,
      treeId: treeId,
      diaryId: diaryId ?? this.diaryId,
      hasPendingDiary: hasPendingDiary ?? this.hasPendingDiary,
    );
  }
}

class _TreeIllustration extends StatefulWidget {
  const _TreeIllustration({required this.weekDiaries});

  final List<DiaryEntry> weekDiaries;

  @override
  State<_TreeIllustration> createState() => _TreeIllustrationState();
}

class _TreeIllustrationState extends State<_TreeIllustration> {
  TreeVectorData? _cachedTreeData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTreeData();
  }

  @override
  void didUpdateWidget(_TreeIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload tree data when weekDiaries changes
    if (widget.weekDiaries != oldWidget.weekDiaries) {
      _loadTreeData();
    }
  }

  Future<void> _loadTreeData() async {
    setState(() => _isLoading = true);
    
    try {
      final treeData = await _buildTreeData();
      if (mounted) {
        setState(() {
          _cachedTreeData = treeData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<TreeVectorData> _buildTreeData() async {
    // Convert DiaryEntry list to emotion data format for TreeVectorUtil
    final emotionData = widget.weekDiaries.map((diary) {
      // Get emotion score, normalize from 0-100 to 0.0-1.0
      // Fallback to "보통" (neutral) if emotion data is missing
      final emotion = diary.dominantEmotion.isEmpty 
          ? 'default' 
          : diary.dominantEmotion;
      final score = diary.emotionScores[emotion] ?? 50.0;
      
      return {
        'emotion': emotion,
        'score': score / 100.0, // Normalize to 0.0-1.0
      };
    }).toList();

    // Generate tree using TreeVectorUtil
    return TreeVectorUtil.svgFor(emotionData: emotionData);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: SizedBox(
        height: 320,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: _cachedTreeData != null
                ? KeyedSubtree(
                    key: ValueKey(_cachedTreeData.hashCode),
                    child: _cachedTreeData!.toPicture(width: 260),
                  )
                : Icon(
                    Icons.park_rounded,
                    key: const ValueKey('fallback'),
                    size: 120,
                    color: AppColors.leafGreen.withValues(alpha: 0.7),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FloatingWriteButton extends StatelessWidget {
  const _FloatingWriteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      right: 24,
      child: GestureDetector(
        onTap: onPressed,
        child: Semantics(
          label: 'write_button',
          button: true,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.trunk.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.trunk.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.edit_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 120),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('불러오는 중...'),
          ],
        ),
      ),
    );
  }
}

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  String _username = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await TokenStorage.readUser();
    if (user != null && mounted) {
      setState(() {
        _username = user['username'] ?? '';
        _displayName = user['displayName'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.trunk.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '내 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 프로필 아바타
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.leafGreen.withOpacity(0.15),
                border: Border.all(
                  color: AppColors.leafGreen.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.leafGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 사용자 정보
            _buildInfoRow('닉네임', _displayName.isNotEmpty ? _displayName : '-'),
            const SizedBox(height: 12),
            _buildInfoRow('아이디', _username.isNotEmpty ? _username : '-'),
            const SizedBox(height: 24),
            // 로그아웃 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class WriteDiaryDialog extends StatefulWidget {
  const WriteDiaryDialog({
    required this.date,
    required this.onSubmit,
    super.key,
  });

  final DateTime date;
  final Future<RemoteDiaryEntry> Function(String title, String content)
  onSubmit;

  @override
  State<WriteDiaryDialog> createState() => _WriteDiaryDialogState();
}

class _WriteDiaryDialogState extends State<WriteDiaryDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) {
      setState(() => _errorMessage = '제목 또는 본문을 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(title, body);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error is DiaryApiException
            ? error.message
            : '저장에 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('M월 d일', 'ko').format(widget.date);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: _DiaryModalCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiaryModalHeader(title: dateLabel),
              const SizedBox(height: 24),
              _DiaryFieldLabel('제목'),
              const SizedBox(height: 8),
              _DiaryTextField(
                controller: _titleController,
                hintText: '제목을 입력하세요',
                textInputAction: TextInputAction.next,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),
              _DiaryFieldLabel('본문'),
              const SizedBox(height: 8),
              _DiaryTextField(
                controller: _bodyController,
                hintText:
                    '오늘 하루는 어땠나요?'
                    '\n느낀 점을 자유롭게 적어 보세요.',
                maxLines: 8,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shadowColor: const Color(0x40000000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장하기'),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ViewDiaryDialog extends StatelessWidget {
  const ViewDiaryDialog({required this.date, required this.entry, super.key});

  final DateTime date;
  final RemoteDiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('M월 d일', 'ko').format(date);
    final parsed = splitDiaryContent(entry.content);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: _DiaryModalCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiaryModalHeader(title: dateLabel),
              const SizedBox(height: 24),
              Text(
                parsed.title.isEmpty ? '오늘 하루' : parsed.title,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                ),
                child: Text(
                  parsed.body.isEmpty ? parsed.title : parsed.body,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryModalCard extends StatelessWidget {
  const _DiaryModalCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(4, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DiaryModalHeader extends StatelessWidget {
  const _DiaryModalHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 24)),
        IconButton(
          splashRadius: 20,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 24),
        ),
      ],
    );
  }
}

class _DiaryFieldLabel extends StatelessWidget {
  const _DiaryFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16));
  }
}

class _DiaryTextField extends StatelessWidget {
  const _DiaryTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.textInputAction,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
        ),
      ),
    );
  }
}

_ModalContent splitDiaryContent(String content) {
  final segments = content.split('\n\n');
  final title = segments.isNotEmpty ? segments.first.trim() : '';
  final body = segments.length > 1
      ? segments.sublist(1).join('\n\n').trim()
      : '';
  return _ModalContent(title: title, body: body);
}

class _ModalContent {
  const _ModalContent({required this.title, required this.body});

  final String title;
  final String body;
}

class _SvgAssetPicture extends StatefulWidget {
  const _SvgAssetPicture({
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.fallback,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final Widget? fallback;

  @override
  State<_SvgAssetPicture> createState() => _SvgAssetPictureState();
}

class _SvgAssetPictureState extends State<_SvgAssetPicture> {
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _verifyAsset();
  }

  @override
  void didUpdateWidget(covariant _SvgAssetPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _isAvailable = true;
      _verifyAsset();
    }
  }

  Future<void> _verifyAsset() async {
    try {
      await rootBundle.load(widget.assetPath);
    } catch (_) {
      if (mounted) {
        setState(() => _isAvailable = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAvailable) {
      return SvgPicture.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        semanticsLabel: widget.semanticLabel,
      );
    }
    return widget.fallback ??
        Icon(
          Icons.image_not_supported_outlined,
          size: widget.width ?? widget.height ?? 24,
          color: Colors.black54,
        );
  }
}
