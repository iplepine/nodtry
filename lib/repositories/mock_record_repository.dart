import '../models/home_state.dart';
import '../models/history_item.dart';
import '../models/plan_model.dart';
import 'record_repository.dart';

/// Mock 데이터 저장소 구현체
class MockRecordRepository implements RecordRepository {
  // 테스트용 상태 설정
  // 개발자 화면에서 이 값을 변경하여 다양한 시나리오 테스트 가능
  List<HomeCardState> _mockHomeCardStates = [
    HomeCardState.planNeeded, // 계획 생성 테스트를 위해 planNeeded로 기본값 변경 (또는 유지)
    // HomeCardState.reportNeeded,
    // HomeCardState.checkNeeded,
    // HomeCardState.waitingForCheck,
  ];

  @override
  Future<List<HomeCardState>> getHomeCardStates() async {
    // 네트워크 딜레이 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockHomeCardStates;
  }

  @override
  Future<List<HistoryItem>> getHistoryItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 1)), // 어제
        title: '책 30분 읽기',
        status: HistoryStatus.verified,
        comment: '어제도 고마워요. 덕분에 책 읽는 시간이 생겼어요.',
        verifierName: '지민',
        verifierImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 2)), // 2일 전
        title: '책 30분 읽기',
        status: HistoryStatus.done,
        comment: '오늘은 조금 늦었지만 완료!',
      ),
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 3)), // 3일 전
        title: '책 30분 읽기',
        status: HistoryStatus.skipped,
        comment: '이번엔 못 했어',
        verifierName: '지민',
        verifierImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jimin',
      ),
      HistoryItem(
        date: DateTime.now().subtract(const Duration(days: 4)), // 4일 전
        title: '책 30분 읽기',
        status: HistoryStatus.verified,
        comment: '꾸준히 하는 모습 멋져요',
        verifierName: '지수',
        verifierImageUrl:
            'https://api.dicebear.com/7.x/avataaars/png?seed=Jisoo',
      ),
    ];
  }

  @override
  Future<void> createPlan(Plan plan) async {
    // Mock: 1초 딜레이 후 성공
    await Future.delayed(const Duration(seconds: 1));
    // 상태를 Active로 변경 시뮬레이션
    _mockHomeCardStates = [
      HomeCardState.reportNeeded,
    ]; // 계획 생기면 ReportNeeded 상태로?
  }

  // Mock 전용 메서드: 상태 변경
  void setMockHomeCardStates(List<HomeCardState> states) {
    _mockHomeCardStates = states;
  }

  @override
  Future<void> deletePlansByUserId(String uid) async {
    // Mock: 딜레이만
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
