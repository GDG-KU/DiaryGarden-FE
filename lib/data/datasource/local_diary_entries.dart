import '../models/diary_entry.dart';

final List<DiaryEntry> localDiaryEntries = List.unmodifiable([
  DiaryEntry(
    id: 'demo-001',
    title: '햇살 좋은 아침',
    content:
        '주말이라 알람 없이 일어났다. 창문을 열었더니 따뜻한 햇살이 방 안을 가득 채웠다. 느긋하게 티를 내려 마시며 책을 조금 읽었다.',
    date: DateTime(2024, 10, 30),
    emotionScores: const {'happy': 0.55, 'calm': 0.35, 'tired': 0.1},
    dominantEmotion: 'happy',
  ),
  DiaryEntry(
    id: 'demo-002',
    title: '퇴근길 카페',
    content:
        '오늘 업무가 길어져 조금 피곤했지만, 집에 가는 길에 새로 생긴 카페에 들렀다. 조용한 음악과 따뜻한 라떼 덕분에 마음이 많이 풀렸다.',
    date: DateTime(2024, 10, 28),
    emotionScores: const {'calm': 0.5, 'tired': 0.3, 'happy': 0.2},
    dominantEmotion: 'calm',
  ),
  DiaryEntry(
    id: 'demo-003',
    title: '늦가을 산책',
    content:
        '저녁 먹고 동네 공원을 한 바퀴 돌았다. 낙엽이 많이 떨어져 발끝에 사각사각 소리가 났다. 차가운 공기를 들이마시니 머리가 맑아지는 느낌이었다.',
    date: DateTime(2024, 10, 27),
    emotionScores: const {'calm': 0.6, 'happy': 0.25, 'sad': 0.15},
    dominantEmotion: 'calm',
  ),
]);
