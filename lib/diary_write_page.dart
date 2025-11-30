import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// [중요] AppColors가 정의된 파일을 import 해야 합니다.
// 경로는 실제 프로젝트에 맞게 수정해주세요.
// 예시: import 'package_name/theme/app_colors.dart';
import 'theme/app_colors.dart';

class DiaryWritePage extends StatefulWidget {
  const DiaryWritePage({super.key});

  @override
  State<DiaryWritePage> createState() => _DiaryWritePageState();
}

class _DiaryWritePageState extends State<DiaryWritePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController
      ..removeListener(_onContentChanged)
      ..dispose();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {});
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.trunk,
              onPrimary: AppColors.textOnTrunk,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.background),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- ADDED ---
  /// AI 코멘트를 받아오는 것을 시뮬레이션하는 가상 함수
  ///
  /// 실제 앱에서는 이 부분에 http 요청 등으로 AI 서버와 통신하는 코드가 들어갑니다.
  Future<String> _getAiComment(String content) async {
    // AI가 분석하는 것처럼 2초간 기다립니다.
    await Future.delayed(const Duration(seconds: 2));

    // content 길이에 따라 간단한 가상 코멘트를 반환합니다.
    if (content.length < 50) {
      return 'AI 코멘트: 오늘 하루는 짧고 간단했네요! 📝';
    } else {
      return 'AI 코멘트: 상세한 일기네요! 감정을 잘 표현해주셨어요. 👍';
    }
  }

  // --- MODIFIED ---
  // void _handleSave() -> Future<void> _handleSave() async 로 변경
  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      // (중요!) async 함수에서 context를 사용할 때는 mounted 확인
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목과 내용을 입력해주세요'),
          backgroundColor: AppColors.leafCoral,
        ),
      );
      return;
    }

    // 1. "저장되었습니다" 스낵바 표시
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('일기가 저장되었습니다! 🌱'),
        backgroundColor: AppColors.leafGreen,
        duration: Duration(milliseconds: 1500),
      ),
    );

    // 2. 컨트롤러 초기화 및 상태 업데이트
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });

    // --- 💡 AI 코멘트 호출 부분 ---
    try {
      // 3. 가상 AI 함수를 호출하고 응답을 기다림 (await)
      final String aiComment = await _getAiComment(content);

      // 4. (중요!) await 이후에 context가 여전히 유효한지(mounted) 확인
      if (!mounted) return;

      // 5. AI 코멘트로 새로운 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiComment),
          backgroundColor: AppColors.trunk, // AI 코멘트용 다른 색상
          duration: const Duration(seconds: 3), // 조금 더 길게 표시
        ),
      );

      // 6. AI 코멘트 스낵바까지 본 후 화면을 닫음
      await Future.delayed(const Duration(seconds: 2)); // 딜레이를 줘서 스낵바를 볼 시간을 줌
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // (선택 사항) AI 호출 중 에러가 나면 에러 스낵바 표시
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI 코멘트 생성 실패: $e'),
          backgroundColor: AppColors.leafCoral,
        ),
      );
    }

    // --- 기존 pop 로직은 AI 로직 안으로 이동됨 ---
    // Future.delayed(const Duration(seconds: 1), () {
    //   if (mounted) {
    //     Navigator.of(context).pop();
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '일기 쓰기',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        // shadowColor: AppColors.trunk.withValues(alpha: 0.1), // withValues가 없어서 주석 처리
        shadowColor: AppColors.trunk.withAlpha(25), // 0.1 * 255 = 25
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('날짜'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDate(),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // color: AppColors.textSecondary.withValues(alpha: 0.3),
                    color:
                        AppColors.textSecondary.withAlpha(77), // 0.3 * 255 = 77
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('제목'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: _buildInputDecoration('오늘의 일기 제목을 입력하세요'),
            ),
            const SizedBox(height: 24),
            _buildLabel('내용'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.5,
              ),
              decoration: _buildInputDecoration(
                '오늘 하루는 어땠나요? 감정을 자유롭게 표현해보세요...',
              ),
              minLines: 10,
              maxLines: 15,
              maxLength: 500,
              buildCounter: (
                context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) {
                return SizedBox(
                  width: double.infinity,
                  child: Text(
                    '$currentLength자',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildTipBox(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        // color: AppColors.textSecondary.withValues(alpha: 0.5),
                        color: AppColors.textSecondary
                            .withAlpha(128), // 0.5 * 255 = 128
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _handleSave, // 수정된 _handleSave 함수가 연결됨
                    icon: const Icon(Icons.save_alt_outlined, size: 20),
                    label: const Text('저장하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.trunk,
                      foregroundColor: AppColors.textOnTrunk,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: AppColors.leafGreen.withValues(alpha: 0.15),
        color: AppColors.leafGreen.withAlpha(38), // 0.15 * 255 = 38
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: AppColors.leafGreen.withValues(alpha: 0.4)),
        border: Border.all(
            color: AppColors.leafGreen.withAlpha(102)), // 0.4 * 255 = 102
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                // color: AppColors.textSecondary.withValues(alpha: 0.8),
                color:
                    AppColors.textSecondary.withAlpha(204), // 0.8 * 255 = 204
              ),
              const SizedBox(width: 8),
              const Text(
                '팁',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipRow('감정을 솔직하게 표현하면 더 정확한 분석이 가능합니다'),
          _buildTipRow('오늘 하루 있었던 일들을 편하게 적어보세요'),
        ],
      ),
    );
  }

  Widget _buildTipRow(String text) {
    final style = TextStyle(
      // color: AppColors.textSecondary.withValues(alpha: 0.9),
      color: AppColors.textSecondary.withAlpha(230), // 0.9 * 255 = 230
      height: 1.4,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        // color: AppColors.textSecondary.withValues(alpha: 0.5),
        color: AppColors.textSecondary.withAlpha(128),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          // color: AppColors.textSecondary.withValues(alpha: 0.3),
          color: AppColors.textSecondary.withAlpha(77),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          // color: AppColors.textSecondary.withValues(alpha: 0.3),
          color: AppColors.textSecondary.withAlpha(77),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.trunk, width: 2),
      ),
    );
  }
}
