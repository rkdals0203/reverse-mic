# Reverse Mic

음성 녹음 및 역재생 앱 - 사용자가 자신의 목소리나 주변 소리를 녹음하고 역재생/속도·피치 조절/효과 적용을 통해 재미있게 경험할 수 있는 오디오 엔터테인먼트 앱입니다.

## 주요 기능

### 🎙️ 핵심 기능
- **음성 녹음**: 마이크를 통한 고품질 오디오 녹음 (WAV 포맷)
- **정방향/역방향 재생**: 녹음된 파일을 정상 또는 역순으로 재생
- **속도 조절**: 0.5x ~ 2.0x 범위의 재생 속도 조절
- **피치 조절**: ±12반음(±1옥타브) 범위의 음정 변경
- **오디오 효과**: 에코, 리버브 효과 적용
- **파일 저장/관리**: 로컬 저장 및 파일 목록 관리
- **공유 기능**: SNS, 메신저 등을 통한 파일 공유

### 🎨 사용자 인터페이스
- **직관적인 원터치 녹음**: 큰 원형 녹음 버튼으로 간편한 조작
- **실시간 상태 표시**: 녹음/재생 상태를 시각적으로 표시
- **슬라이더 기반 조절**: 속도/피치를 직관적으로 조절
- **파형 시각화**: 오디오 파형 표시 (향후 구현 예정)
- **다크모드 지원**: 시스템 설정에 따른 자동 테마 전환

### 📁 파일 관리
- **검색 기능**: 파일 이름으로 검색
- **정렬 옵션**: 날짜, 이름, 재생시간 순 정렬
- **일괄 작업**: 여러 파일 선택하여 공유/삭제
- **슬라이드 액션**: 스와이프를 통한 빠른 파일 작업

## 기술 스택

- **Framework**: Flutter 3.10+
- **언어**: Dart
- **상태 관리**: Provider
- **오디오 처리**: 
  - `record`: 음성 녹음
  - `just_audio`: 오디오 재생
  - `flutter_sound`: 고급 오디오 처리
- **파일 관리**: `path_provider`, `file_picker`
- **공유 기능**: `share_plus`
- **권한 관리**: `permission_handler`
- **UI 컴포넌트**: `flutter_slidable`, `lottie`

## 시작하기

### 필요 조건
- Flutter 3.10.0 이상
- Dart 3.0.0 이상
- Android SDK 21+ (Android 5.0+)
- iOS 11.0+

### 설치 방법

1. **저장소 클론**
   ```bash
   git clone https://github.com/your-username/reverse-mic.git
   cd reverse-mic
   ```

2. **의존성 설치**
   ```bash
   flutter pub get
   ```

3. **플랫폼별 설정**

   **Android:**
   - `android/app/src/main/AndroidManifest.xml`에서 권한 확인
   - 최소 SDK 버전: 21

   **iOS:**
   - `ios/Runner/Info.plist`에서 권한 설정 확인
   - 최소 iOS 버전: 11.0

4. **앱 실행**
   ```bash
   flutter run
   ```

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── models/                      # 데이터 모델
│   └── audio_file_model.dart
├── providers/                   # 상태 관리
│   ├── audio_provider.dart
│   └── file_manager_provider.dart
├── screens/                     # 화면
│   ├── home_screen.dart
│   └── file_list_screen.dart
├── services/                    # 서비스
│   └── audio_effects_service.dart
├── utils/                       # 유틸리티
│   └── app_theme.dart
└── widgets/                     # 재사용 가능한 위젯
    ├── recording_button.dart
    ├── audio_player_widget.dart
    ├── audio_controls_widget.dart
    └── file_list_item.dart
```

## 사용법

### 기본 녹음 및 재생
1. 메인 화면에서 마이크 버튼을 터치하여 녹음 시작
2. 녹음 중 빨간색 정지 버튼을 터치하여 녹음 종료
3. 녹음 완료 후 정방향/역방향 재생 버튼으로 오디오 재생

### 오디오 효과 적용
1. 녹음 완료 후 오디오 효과 섹션에서 설정
2. 속도 슬라이더로 재생 속도 조절 (0.5x ~ 2.0x)
3. 피치 슬라이더로 음정 조절 (-12 ~ +12 반음)
4. 에코/리버브 토글 버튼으로 효과 적용

### 파일 관리
1. 상단 폴더 아이콘을 터치하여 파일 목록 화면으로 이동
2. 파일을 좌우로 스와이프하여 공유/이름변경/삭제
3. 길게 터치하여 다중 선택 모드 진입
4. 검색 아이콘으로 파일 이름 검색

## 권한 설정

### Android
- `RECORD_AUDIO`: 음성 녹음
- `WRITE_EXTERNAL_STORAGE`: 파일 저장
- `READ_EXTERNAL_STORAGE`: 파일 읽기

### iOS
- `NSMicrophoneUsageDescription`: 마이크 사용
- `NSPhotoLibraryUsageDescription`: 파일 저장

## 향후 계획

- [ ] **실시간 역재생 미리듣기**: 녹음하면서 역재생 확인
- [ ] **파형 시각화**: 오디오 파형 표시 및 편집 기능
- [ ] **더 많은 효과**: 로봇보이스, 변조 효과 추가
- [ ] **클라우드 동기화**: Google Drive, iCloud 연동
- [ ] **소셜 기능**: 앱 내 클립 공유 및 챌린지 모드
- [ ] **광고 및 인앱 결제**: 수익화 모델 구현

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 기여하기

1. 프로젝트를 포크합니다
2. 기능 브랜치를 생성합니다 (`git checkout -b feature/AmazingFeature`)
3. 변경사항을 커밋합니다 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치에 푸시합니다 (`git push origin feature/AmazingFeature`)
5. Pull Request를 생성합니다

## 문의사항

프로젝트에 대한 질문이나 제안사항이 있으시면 이슈를 생성하거나 이메일로 연락주세요.

---

**Reverse Mic** - 음성의 새로운 재미를 발견하세요! 🎵
