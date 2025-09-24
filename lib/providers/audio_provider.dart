import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/audio_file_model.dart';
import '../services/audio_effects_service.dart';

enum RecordingState { idle, recording, paused }
enum PlaybackState { idle, playing, paused }

class AudioProvider extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final AudioEffectsService _effectsService = AudioEffectsService();

  // 상태 관리
  RecordingState _recordingState = RecordingState.idle;
  PlaybackState _playbackState = PlaybackState.idle;
  
  // 현재 파일 정보
  AudioFileModel? _currentAudioFile;
  String? _currentRecordingPath;
  
  // 오디오 설정
  double _playbackSpeed = 1.0;
  double _pitch = 0.0; // -12 ~ +12 반음
  bool _isReversed = false;
  bool _echoEnabled = false;
  bool _reverbEnabled = false;
  
  // 녹음 시간
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Getters
  RecordingState get recordingState => _recordingState;
  PlaybackState get playbackState => _playbackState;
  AudioFileModel? get currentAudioFile => _currentAudioFile;
  double get playbackSpeed => _playbackSpeed;
  double get pitch => _pitch;
  double get pitchShift => _pitch; // 파형 위젯용 별칭
  bool get isReversed => _isReversed;
  bool get echoEnabled => _echoEnabled;
  bool get reverbEnabled => _reverbEnabled;
  Duration get recordingDuration => _recordingDuration;
  Duration get playbackPosition => _playbackPosition;
  Duration get currentPosition => _playbackPosition; // 파형 위젯용 별칭
  Duration get duration => _totalDuration; // 파형 위젯용 별칭
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _playbackState == PlaybackState.playing; // 파형 위젯용

  AudioProvider() {
    _initializePlayer();
  }

  void _initializePlayer() {
    // 플레이어 상태 리스너
    _player.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
          _playbackState = PlaybackState.idle;
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          break;
        case ProcessingState.ready:
          if (state.playing) {
            _playbackState = PlaybackState.playing;
          } else {
            _playbackState = PlaybackState.paused;
          }
          break;
        case ProcessingState.completed:
          _playbackState = PlaybackState.idle;
          break;
      }
      notifyListeners();
    });

    // 재생 위치 리스너
    _player.positionStream.listen((position) {
      _playbackPosition = position;
      notifyListeners();
    });

    // 총 재생 시간 리스너
    _player.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  // 권한 확인
  Future<bool> _checkPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    final storageStatus = await Permission.storage.status;
    
    if (microphoneStatus.isDenied) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) return false;
    }
    
    if (storageStatus.isDenied) {
      final result = await Permission.storage.request();
      if (!result.isGranted) return false;
    }
    
    return true;
  }

  // 녹음 시작
  Future<bool> startRecording() async {
    try {
      if (!await _checkPermissions()) {
        return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentRecordingPath = '${directory.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      _recordingState = RecordingState.recording;
      _recordingDuration = Duration.zero;
      
      // 녹음 시간 업데이트 타이머
      _startRecordingTimer();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('녹음 시작 오류: $e');
      return false;
    }
  }

  // 녹음 중지
  Future<void> stopRecording() async {
    try {
      await _recorder.stop();
      _recordingState = RecordingState.idle;
      
      if (_currentRecordingPath != null) {
        _currentAudioFile = AudioFileModel(
          name: '녹음_${DateTime.now().day}_${DateTime.now().hour}시${DateTime.now().minute}분',
          path: _currentRecordingPath!,
          duration: _recordingDuration,
          createdAt: DateTime.now(),
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('녹음 중지 오류: $e');
    }
  }

  // 녹음 시간 타이머
  void _startRecordingTimer() {
    // 실제 구현에서는 Timer.periodic을 사용하여 1초마다 업데이트
    // 여기서는 간단히 구현
  }

  // 오디오 재생 (정방향)
  Future<void> playAudio() async {
    if (_currentAudioFile == null) return;

    try {
      String audioPath = _currentAudioFile!.path;
      
      // 효과가 적용된 경우 임시 파일 생성
      if (_isReversed || _pitch != 0.0 || _echoEnabled || _reverbEnabled) {
        audioPath = await _applyEffects(_currentAudioFile!.path);
      }

      await _player.setFilePath(audioPath);
      await _player.setSpeed(_playbackSpeed);
      await _player.play();
    } catch (e) {
      debugPrint('재생 오류: $e');
    }
  }

  // 오디오 재생 (역방향)
  Future<void> playReversedAudio() async {
    _isReversed = true;
    await playAudio();
  }

  // 재생 일시정지
  Future<void> pauseAudio() async {
    await _player.pause();
  }

  // 재생 메서드 (간단한 버전)
  Future<void> play() async {
    await playAudio();
  }

  // 일시정지 메서드 (간단한 버전)
  Future<void> pause() async {
    await pauseAudio();
  }

  // 재생 중지
  Future<void> stopAudio() async {
    await _player.stop();
    _playbackPosition = Duration.zero;
    notifyListeners();
  }

  // 속도 조절
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    _player.setSpeed(_playbackSpeed);
    notifyListeners();
  }

  // 피치 조절
  void setPitch(double pitch) {
    _pitch = pitch.clamp(-12.0, 12.0);
    notifyListeners();
  }

  // 역재생 토글
  void toggleReverse() {
    _isReversed = !_isReversed;
    notifyListeners();
  }

  // 역재생 설정
  void setReverse(bool isReversed) {
    _isReversed = isReversed;
    notifyListeners();
  }

  // 에코 효과 토글
  void toggleEcho() {
    _echoEnabled = !_echoEnabled;
    notifyListeners();
  }

  // 리버브 효과 토글
  void toggleReverb() {
    _reverbEnabled = !_reverbEnabled;
    notifyListeners();
  }

  // 효과 적용
  Future<String> _applyEffects(String originalPath) async {
    return await _effectsService.applyEffects(
      originalPath,
      isReversed: _isReversed,
      pitch: _pitch,
      echoEnabled: _echoEnabled,
      reverbEnabled: _reverbEnabled,
    );
  }

  // 파일 저장
  Future<bool> saveCurrentAudio(String customName) async {
    if (_currentAudioFile == null) return false;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final savedPath = '${directory.path}/saved/$customName.wav';
      
      // 디렉토리 생성
      final savedDir = Directory('${directory.path}/saved');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      // 파일 복사
      final originalFile = File(_currentAudioFile!.path);
      await originalFile.copy(savedPath);

      return true;
    } catch (e) {
      debugPrint('파일 저장 오류: $e');
      return false;
    }
  }

  // 리소스 정리
  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
