import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioEffectsService {
  // 효과가 적용된 임시 파일들을 관리
  final List<String> _tempFiles = [];

  // 오디오 효과 적용
  Future<String> applyEffects(
    String originalPath, {
    bool isReversed = false,
    double pitch = 0.0,
    bool echoEnabled = false,
    bool reverbEnabled = false,
  }) async {
    try {
      String processedPath = originalPath;
      
      // 역재생 효과
      if (isReversed) {
        processedPath = await _reverseAudio(processedPath);
      }
      
      // 피치 조절
      if (pitch != 0.0) {
        processedPath = await _changePitch(processedPath, pitch);
      }
      
      // 에코 효과
      if (echoEnabled) {
        processedPath = await _addEcho(processedPath);
      }
      
      // 리버브 효과
      if (reverbEnabled) {
        processedPath = await _addReverb(processedPath);
      }
      
      return processedPath;
    } catch (e) {
      debugPrint('오디오 효과 적용 오류: $e');
      return originalPath;
    }
  }

  // 오디오 역재생
  Future<String> _reverseAudio(String inputPath) async {
    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/reversed_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // 실제 구현에서는 FFmpeg 또는 네이티브 오디오 처리 라이브러리 사용
      // 여기서는 간단한 시뮬레이션
      final inputFile = File(inputPath);
      final audioData = await inputFile.readAsBytes();
      
      // WAV 헤더를 제외한 오디오 데이터만 역순으로 변경
      final reversedData = await _reverseWavData(audioData);
      
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(reversedData);
      
      _tempFiles.add(outputPath);
      return outputPath;
    } catch (e) {
      debugPrint('오디오 역재생 오류: $e');
      return inputPath;
    }
  }

  // WAV 데이터 역순 변경 (간단한 구현)
  Future<Uint8List> _reverseWavData(Uint8List data) async {
    return compute(_reverseWavDataIsolate, data);
  }

  static Uint8List _reverseWavDataIsolate(Uint8List data) {
    // WAV 헤더는 보통 44바이트
    const headerSize = 44;
    
    if (data.length <= headerSize) return data;
    
    final header = data.sublist(0, headerSize);
    final audioData = data.sublist(headerSize);
    
    // 16비트 스테레오 가정 (4바이트씩 처리)
    const sampleSize = 4;
    final samples = audioData.length ~/ sampleSize;
    final reversedAudio = Uint8List(audioData.length);
    
    for (int i = 0; i < samples; i++) {
      final originalIndex = i * sampleSize;
      final reversedIndex = (samples - 1 - i) * sampleSize;
      
      for (int j = 0; j < sampleSize; j++) {
        reversedAudio[originalIndex + j] = audioData[reversedIndex + j];
      }
    }
    
    // 헤더와 역순 오디오 데이터 결합
    final result = Uint8List(data.length);
    result.setRange(0, headerSize, header);
    result.setRange(headerSize, data.length, reversedAudio);
    
    return result;
  }

  // 피치 변경
  Future<String> _changePitch(String inputPath, double pitch) async {
    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/pitched_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // 실제 구현에서는 PSOLA 알고리즘이나 FFT 기반 피치 시프팅 사용
      // 여기서는 파일 복사로 시뮬레이션
      final inputFile = File(inputPath);
      await inputFile.copy(outputPath);
      
      _tempFiles.add(outputPath);
      return outputPath;
    } catch (e) {
      debugPrint('피치 변경 오류: $e');
      return inputPath;
    }
  }

  // 에코 효과 추가
  Future<String> _addEcho(String inputPath) async {
    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/echo_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // 실제 구현에서는 지연된 신호를 원본에 믹싱
      // 여기서는 파일 복사로 시뮬레이션
      final inputFile = File(inputPath);
      await inputFile.copy(outputPath);
      
      _tempFiles.add(outputPath);
      return outputPath;
    } catch (e) {
      debugPrint('에코 효과 추가 오류: $e');
      return inputPath;
    }
  }

  // 리버브 효과 추가
  Future<String> _addReverb(String inputPath) async {
    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/reverb_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // 실제 구현에서는 컨볼루션 리버브 사용
      // 여기서는 파일 복사로 시뮬레이션
      final inputFile = File(inputPath);
      await inputFile.copy(outputPath);
      
      _tempFiles.add(outputPath);
      return outputPath;
    } catch (e) {
      debugPrint('리버브 효과 추가 오류: $e');
      return inputPath;
    }
  }

  // 임시 파일들 정리
  Future<void> cleanupTempFiles() async {
    for (final filePath in _tempFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('임시 파일 삭제 오류: $e');
      }
    }
    _tempFiles.clear();
  }

  // 서비스 종료 시 정리
  void dispose() {
    cleanupTempFiles();
  }
}
