import 'package:flutter/material.dart';

enum ViewMode { month, year }

class MyForestPage extends StatefulWidget {
  final ViewMode initialMode; // 👈 추가
  const MyForestPage({super.key, this.initialMode = ViewMode.month});

  @override
  State<MyForestPage> createState() => _MyForestPageState();
}

class _MyForestPageState extends State<MyForestPage> {
  ViewMode mode = ViewMode.month;
  DateTime now = DateTime.now();
  DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool loading = false;
  List<TreeItem> items = [];

  final repo = ForestRepo();

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode; // 👈 초기 모드 반영

    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    if (mode == ViewMode.month) {
      final range = DateTimeRange(
        start: DateTime(cursor.year, cursor.month, 1),
        end: DateTime(cursor.year, cursor.month + 1, 1),
      );
      items = await repo.fetchByRange(range);
    } else {
      items = await repo.fetchByYear(cursor.year);
    }
    setState(() => loading = false);
  }

  void _prev() {
    setState(() {
      cursor = mode == ViewMode.month
          ? DateTime(cursor.year, cursor.month - 1, 1)
          : DateTime(cursor.year - 1, 1, 1);
    });
    _load();
  }

  void _next() {
    setState(() {
      cursor = mode == ViewMode.month
          ? DateTime(cursor.year, cursor.month + 1, 1)
          : DateTime(cursor.year + 1, 1, 1);
    });
    _load();
  }

  String _title() {
    if (mode == ViewMode.month) return "${cursor.year}년 ${cursor.month}월";
    return "${cursor.year}년";
  }

  @override
  Widget build(BuildContext context) {
    final isMonth = mode == ViewMode.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text("나의 숲"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ToggleButtons(
              isSelected: [isMonth, !isMonth],
              onPressed: (i) {
                setState(() {
                  mode = i == 0 ? ViewMode.month : ViewMode.year;
                  cursor = mode == ViewMode.month
                      ? DateTime(now.year, now.month, 1)
                      : DateTime(now.year, 1, 1);
                });
                _load();
              },
              constraints: const BoxConstraints(minWidth: 56, minHeight: 32),
              children: const [Text("월"), Text("년")],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prev,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _title(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _next,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? _Empty()
                : isMonth
                ? _MonthGrid(
                    items: items,
                    year: cursor.year,
                    month: cursor.month,
                  )
                : _YearGrid(items: items, year: cursor.year),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.park_outlined, size: 64),
          SizedBox(height: 8),
          Text("공원에 숲이 없어요", style: TextStyle(fontSize: 16)),
          SizedBox(height: 4),
          Text("일기를 쓰면 나무가 자라요", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final List<TreeItem> items;
  final int year;
  final int month;
  const _MonthGrid({
    required this.items,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    // day -> item 맵
    final map = <int, TreeItem>{};
    for (final it in items) {
      if (it.date.year == year && it.date.month == month) {
        map[it.date.day] = it;
      }
    }
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon..7=Sun
    final leading = (firstWeekday + 6) % 7; // 월시작 그리드 offset

    final totalCells = leading + daysInMonth;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: totalCells,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (_, i) {
          if (i < leading) return const SizedBox.shrink();
          final day = i - leading + 1;
          final it = map[day];
          return _DayCell(day: day, item: it);
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final TreeItem? item;
  const _DayCell({required this.day, required this.item});

  Color _leafColor() {
    if (item == null) return Colors.grey.withOpacity(.2);
    switch (item!.mood) {
      case 'joy':
        return const Color(0xFF93E6AA); // 연오 팔레트
      case 'sad':
        return const Color(0xFF9FC0F5);
      case 'anger':
        return const Color(0xFFEB875F);
      default:
        return const Color(0xFFFAE469);
    }
  }

  IconData _treeIcon() {
    if (item == null) return Icons.crop_square_rounded;
    switch (item!.level) {
      case 1:
        return Icons.park_outlined;
      case 2:
        return Icons.park;
      default:
        return Icons.forest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _leafColor();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: c.withOpacity(.18),
        border: Border.all(color: c.withOpacity(.6)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 6,
            child: Text("$day", style: const TextStyle(fontSize: 12)),
          ),
          Center(child: Icon(_treeIcon(), size: 28, color: c.withOpacity(.9))),
        ],
      ),
    );
  }
}

class _YearGrid extends StatelessWidget {
  final List<TreeItem> items;
  final int year;
  const _YearGrid({required this.items, required this.year});

  @override
  Widget build(BuildContext context) {
    // 월별 카운트/레벨 평균
    final cnt = List<int>.filled(12, 0);
    final lvl = List<int>.filled(12, 0);
    for (final it in items) {
      if (it.date.year == year) {
        final m = it.date.month - 1;
        cnt[m] += 1;
        lvl[m] += it.level;
      }
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (_, i) {
          final c = cnt[i];
          final avg = c == 0 ? 0 : (lvl[i] / c);
          final tone = c == 0
              ? Colors.grey.withOpacity(.15)
              : Colors.green.withOpacity(.15 + (avg.clamp(0, 3) / 3) * .35);
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tone.withOpacity(.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${i + 1}월",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.forest, size: 20),
                    const SizedBox(width: 6),
                    Text("x$c"),
                    const Spacer(),
                    Icon(
                      avg >= 2.5
                          ? Icons.forest
                          : avg >= 1.5
                          ? Icons.park
                          : Icons.park_outlined,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TreeItem {
  final DateTime date;
  final int level; // 1=초급,2=중급,3=상급
  final String mood; // joy/sad/anger/neutral
  TreeItem({required this.date, required this.level, required this.mood});
}

class ForestRepo {
  // TODO: Firebase 연동으로 교체
  Future<List<TreeItem>> fetchByRange(DateTimeRange r) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // 데모: 특정 달만 샘플
    if (r.start.month % 2 == 0) return [];
    return [
      TreeItem(
        date: r.start.add(const Duration(days: 0)),
        level: 1,
        mood: 'joy',
      ),
      TreeItem(
        date: r.start.add(const Duration(days: 2)),
        level: 2,
        mood: 'neutral',
      ),
      TreeItem(
        date: r.start.add(const Duration(days: 5)),
        level: 3,
        mood: 'anger',
      ),
      TreeItem(
        date: r.start.add(const Duration(days: 11)),
        level: 2,
        mood: 'sad',
      ),
      TreeItem(
        date: r.start.add(const Duration(days: 18)),
        level: 1,
        mood: 'joy',
      ),
      TreeItem(
        date: r.start.add(const Duration(days: 23)),
        level: 3,
        mood: 'joy',
      ),
    ];
  }

  Future<List<TreeItem>> fetchByYear(int y) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final list = <TreeItem>[];
    for (var m = 1; m <= 12; m++) {
      for (var d = 1; d <= 3; d++) {
        if ((m + d) % 4 == 0) continue;
        list.add(
          TreeItem(
            date: DateTime(y, m, (d * 6).clamp(1, 28)),
            level: (1 + (m + d) % 3),
            mood: const ['joy', 'sad', 'anger', 'neutral'][(m + d) % 4],
          ),
        );
      }
    }
    return list;
  }
}
