import 'package:diary_garden/core/config/api_config.dart';
import 'package:diary_garden/core/storage/token_storage.dart';
import 'package:diary_garden/core/theme/app_colors.dart';
import 'package:diary_garden/data/datasource/diary_api_client.dart';
import 'package:diary_garden/data/models/diary_entry.dart';
import 'package:diary_garden/data/models/remote_diary_entry.dart';
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
  late List<_DayStatusModel> _dayStatuses;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _diaryApiClient = DiaryApiClient();
    _dayStatuses = _generateWeekStatuses();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final stored = await TokenStorage.readToken();
    setState(() {
      _authToken = stored ?? ApiConfig.maybeAuthToken;
    });
    await _loadRecentDiaries();
  }

  List<_DayStatusModel> _generateWeekStatuses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday % 7));
    return List.generate(_weekdayLabels.length, (index) {
      final date = start.add(Duration(days: index));
      final treeId = _treeIdForDate(date);
      return _DayStatusModel(label: _weekdayLabels[index], date: date, treeId: treeId);
    });
  }

  Future<void> _loadRecentDiaries() async {
    final token = _authToken;
    if (token == null) return;
    try {
      final diaries = await _diaryApiClient.fetchDiaries(authToken: token, limit: 7);
      if (!mounted) return;
      setState(() {
        _dayStatuses = _dayStatuses.map((status) {
          final match = _findDiaryForDate(diaries, status.date);
          if (match == null) {
            return status;
          }
          return status.copyWith(diaryId: match.id);
        }).toList();
      });
    } catch (error) {
      debugPrint('Failed to load diaries: $error');
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

  String _treeIdForDate(DateTime date) => 'tree-${DateFormat('yyyyMMdd').format(date)}';

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
    final entry = await _diaryApiClient.createDiary(
      authToken: token,
      treeId: _treeIdForDate(date),
      content: _composeContent(title, body),
    );

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
  }

  Future<void> _handleDayTap(_DayStatusModel status) async {
    if (!status.hasDiary || status.diaryId == null) {
      _showSnackBar('아직 작성된 일기가 없어요.');
      return;
    }
    final token = _authToken;
    if (token == null) {
      _showSnackBar('API 토큰이 필요합니다.');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );

    try {
      final entry = await _diaryApiClient.fetchDiary(id: status.diaryId!, authToken: token);
      if (!mounted) return;
      Navigator.of(context).pop();
      final diaryEntry = _toDiaryEntry(entry);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiaryReadPage(entries: [diaryEntry]),
        ),
      );
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
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
    final parsed = _splitDiaryContent(entry.content);
    return DiaryEntry(
      id: entry.id,
      title: parsed.title.isEmpty ? '오늘 하루' : parsed.title,
      content: parsed.body.isEmpty ? parsed.title : parsed.body,
      date: entry.writtenDate,
      emotionScores: const {'default': 1.0},
      dominantEmotion: 'default',
    );
  }

  ({String title, String body}) _splitDiaryContent(String content) {
    final segments = content.split('\n\n');
    final title = segments.isNotEmpty ? segments.first.trim() : '';
    final body = segments.length > 1
        ? segments.sublist(1).join('\n\n').trim()
        : '';
    return (title: title, body: body);
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
      builder: (_) => ProfileDialog(
        onLogout: _handleLogout,
      ),
    );
  }

  Future<void> _handleLogout() async {
    await TokenStorage.clearToken();
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
                statuses: _dayStatuses,
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
    required this.statuses,
    required this.onDayTap,
    required this.onMenuTap,
    required this.onCalendarTap,
    required this.onProfileTap,
  });

  final List<_DayStatusModel> statuses;
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
          const SizedBox(height: 48),
          const _DayHeaderRow(),
          const SizedBox(height: 10),
          _DayStatusRow(statuses: statuses, onTap: onDayTap),
          const SizedBox(height: 116),
          _TreeIllustration(writtenCount: statuses.where((s) => s.hasDiary).length),
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
            fallback: Icon(Icons.image_outlined, color: Colors.black54, size: 24),
          )
        : Image.asset(
            assetPath,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          );

    Widget child = SizedBox(width: 48, height: 48, child: Center(child: imageWidget));
    child = Semantics(label: semanticLabel, button: onTap != null, child: child);

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
            _DayBubble(
              status: status,
              onTap: () => onTap(status),
            ),
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
    final assetPath = status.hasDiary
        ? 'assets/images/writtenDay.png'
        : 'assets/images/unWrittenDay.png';

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
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: status.hasDiary ? AppColors.leafGreen : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
              child: Icon(
                status.hasDiary ? Icons.eco : Icons.add,
                color: status.hasDiary ? Colors.white : Colors.black38,
                size: 20,
              ),
            ),
          ),
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
  });

  final String label;
  final DateTime date;
  final String treeId;
  final String? diaryId;

  bool get hasDiary => diaryId != null;

  _DayStatusModel copyWith({String? diaryId}) {
    return _DayStatusModel(
      label: label,
      date: date,
      treeId: treeId,
      diaryId: diaryId ?? this.diaryId,
    );
  }
}

class _TreeIllustration extends StatelessWidget {
  const _TreeIllustration({required this.writtenCount});

  final int writtenCount;

  String get _assetPath {
    final level = switch (writtenCount) {
      0 => 1,
      1 || 2 => 2,
      3 || 4 || 5 => 3,
      _ => 4,
    };
    return 'assets/svgs/tree_level_$level.svg';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: SizedBox(
        height: 320,
        child: Center(
          child: _SvgAssetPicture(
            assetPath: _assetPath,
            width: 260,
            height: 260,
            semanticLabel: 'tree_level',
            fallback: Icon(
              Icons.park_rounded,
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
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: onPressed,
          child: Semantics(
            label: 'write_button',
            button: true,
            child: Image.asset(
              'assets/images/WriteButton.png',
              width: 88,
              height: 88,
              errorBuilder: (context, error, stack) => Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.black87, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.black87, size: 32),
              ),
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

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(44),
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(4, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: '닫기',
                splashRadius: 18,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(120),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Profile.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                    size: 64,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '나의 일기장',
              style: TextStyle(fontSize: 24, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.black.withOpacity(0.1)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.black87),
                label: const Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shadowColor: const Color(0x33000000),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return widget.fallback ?? Icon(
      Icons.image_not_supported_outlined,
      size: widget.width ?? widget.height ?? 24,
      color: Colors.black54,
    );
  }
}
