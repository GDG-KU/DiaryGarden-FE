# diary_garden

## 📁 프로젝트 디렉토리 구조

구조는 크게 Data, Domain, Presentation의 3계층과 이들을 지원하는 Core로 나뉩니다.

### 📂 lib/

main.dart

앱의 진입점(Entry Point)입니다. MaterialApp을 정의하고, 앱 초기화(의존성 주입(DI), 환경설정 등)를 수행합니다.

### 📂 core

앱 전반에서 사용되는 공통 핵심 모듈을 관리합니다. 다른 계층(Data, Domain, Presentation)에 의존하지 않거나, 공통으로 필요한 기반 요소를 포함합니다.

constants/: API 기본 URL, 라우트 이름 등 앱 전역상수.

di/: 의존성 주입(Dependency Injection) 설정. (e.g., get_it, riverpod 설정)

network/: 네트워크 통신 클라이언트(e.g., Dio 또는 http)의 인스턴스, 인터셉터 설정.

services/: 네비게이션, 로컬 알림 등 앱의 백그라운드나 기반 서비스를 관리.

theme/: 앱의 공통 시각적 테마 (색상, 폰트 스타일, 테마 데이터).

utils/: 날짜 포매팅, 유효성 검사 등 공통 헬퍼(Helper) 함수.

widgets/: CustomButton, LoadingSpinner처럼 앱 내 여러 화면에서 재사용되는 공통 위젯.

### 📂 data

데이터 소스(API, DB 등)와의 통신을 담당하는 데이터 계층입니다.

models/: API 응답이나 DB 스키마와 1:1로 매핑되는 데이터 모델 (DTOs - Data Transfer Objects). (예: DiaryEntry)

datasources/: 실제 데이터 입출력을 담당하는 부분.

remote/: 원격 서버 API와 통신하는 클래스 (e.g., DiaryApiService).

local/: 로컬 DB(SQLite, Hive), SharedPreferences, 또는 개발용 목업(Mock) 데이터를 관리.

repositories/: domain 계층의 Repository 인터페이스에 대한 구현체입니다. (e.g., DiaryRepositoryImpl). remote와 local 데이터 소스를 조합하여 데이터를 가져옵니다.

### 📂 domain

앱의 핵심 비즈니스 로직을 담당하는 도메인 계층입니다.

repositories/: 데이터 저장소의 **인터페이스(추상 클래스)**를 정의합니다. "무엇을" 가져올지만 정의하고, "어떻게" 가져오는지는 data 계층에 위임합니다. (예: abstract class DiaryRepository)

usecases/ (또는 use_cases): 앱의 특정 기능(유스케이스)을 나타내는 클래스입니다. 여러 Repository를 조합하여 하나의 비즈니스 로직을 수행합니다. (예: SaveDiaryUseCase)

entities/: (선택 사항) data/models와 비즈니스 로직의 핵심 객체(entities)를 분리할 때 사용합니다.

### 📂 presentation

UI와 상태 관리를 담당하는 표현 계층입니다.

features/: 앱의 각 기능을 독립된 폴더로 관리합니다. (e.g., home, diary, auth)

view/: 실제 화면을 구성하는 스크린(페이지) 위젯. (e.g., home_screen.dart)

widgets/: *해당 기능(feature)*의 화면에서만 사용되는 비교적 작은 단위의 위젯.

bloc/ (또는 provider/, viewmodel/): 해당 기능의 상태 관리 로직 (Bloc, Provider, ViewModel 등).

a_app_wide_providers/: (선택 사항) 인증 상태, 유저 정보처럼 앱 전역에서 필요한 상태를 관리하는 Provider/Bloc.

### 📂 test

작성된 코드를 검증하기 위한 테스트 코드를 관리합니다.

unit/: 유닛 테스트 (주로 domain, data 계층).

widget/: 위젯 테스트 (presentation 계층).

integration/: 통합 테스트.
