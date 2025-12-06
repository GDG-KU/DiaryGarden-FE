import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/storage/diary_storage.dart';
import '../../../core/storage/pending_diary_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
        final hour = prefs.getInt('reminder_hour') ?? 21;
        final minute = prefs.getInt('reminder_minute') ?? 0;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load settings: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reminder_enabled', _reminderEnabled);
      await prefs.setInt('reminder_hour', _reminderTime.hour);
      await prefs.setInt('reminder_minute', _reminderTime.minute);
      
      // Schedule or cancel notification
      if (_reminderEnabled) {
        await NotificationService.scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
      } else {
        await NotificationService.cancelReminder();
      }
    } catch (e) {
      debugPrint('❌ Failed to save settings: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 저장에 실패했어요')),
      );
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.trunk,
              onPrimary: Colors.white,
              surface: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
      await _saveSettings();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니다?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leafCoral,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await TokenStorage.clearToken();
      await DiaryStorage.clear();
      await PendingDiaryStorage.clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $hour:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Reminder section
                _SectionCard(
                  title: '일기 리마인더',
                  icon: Icons.notifications_rounded,
                  iconColor: AppColors.leafYellow,
                  children: [
                    SwitchListTile(
                      title: const Text('매일 알림 받기'),
                      subtitle: Text(
                        _reminderEnabled 
                            ? '${_formatTime(_reminderTime)}에 알림' 
                            : '일기 작성 알림을 켜보세요',
                      ),
                      value: _reminderEnabled,
                      onChanged: (value) async {
                        setState(() => _reminderEnabled = value);
                        await _saveSettings();
                      },
                      activeColor: AppColors.trunk,
                    ),
                    if (_reminderEnabled)
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('알림 시간'),
                        trailing: TextButton(
                          onPressed: _selectTime,
                          child: Text(
                            _formatTime(_reminderTime),
                            style: TextStyle(
                              color: AppColors.trunk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Account section
                _SectionCard(
                  title: '계정',
                  icon: Icons.person_outline,
                  iconColor: AppColors.leafBlue,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.leafCoral),
                      title: const Text('로그아웃'),
                      onTap: _handleLogout,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // App info section
                _SectionCard(
                  title: '앱 정보',
                  icon: Icons.info_outline,
                  iconColor: AppColors.leafGreen,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.apps),
                      title: Text('버전'),
                      trailing: Text('1.0.0'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
