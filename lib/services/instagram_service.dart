import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class InstagramService {
  static final InstagramService _instance = InstagramService._internal();
  factory InstagramService() => _instance;
  InstagramService._internal();

  final Dio _dio = Dio();

  /// 인스타그램 URL에서 오디오를 추출하고 저장
  Future<String?> extractAudioFromInstagramUrl(String instagramUrl) async {
    try {
      debugPrint('인스타그램 URL 처리 시작: $instagramUrl');
      
      // URL 유효성 검사
      if (!_isValidInstagramUrl(instagramUrl)) {
        throw Exception('유효하지 않은 인스타그램 URL입니다.');
      }

      // 릴스 URL인지 확인
      if (!_isReelsUrl(instagramUrl)) {
        throw Exception('릴스 URL이 아닙니다. 릴스 URL을 공유해주세요.');
      }

      // 오디오 URL 추출 (실제 구현에서는 인스타그램 API 또는 웹 스크래핑 필요)
      String? audioUrl = await _extractAudioUrl(instagramUrl);
      
      if (audioUrl == null) {
        throw Exception('오디오 URL을 찾을 수 없습니다.');
      }

      // 오디오 다운로드
      String savedPath = await _downloadAudio(audioUrl, instagramUrl);
      
      debugPrint('오디오 저장 완료: $savedPath');
      return savedPath;
      
    } catch (e) {
      debugPrint('인스타그램 오디오 추출 오류: $e');
      rethrow;
    }
  }

  /// URL이 유효한 인스타그램 URL인지 확인
  bool _isValidInstagramUrl(String url) {
    return url.contains('instagram.com') || url.contains('instagr.am');
  }

  /// 릴스 URL인지 확인
  bool _isReelsUrl(String url) {
    return url.contains('/reel/') || url.contains('/reels/');
  }

  /// 인스타그램 URL에서 오디오 URL 추출
  /// 실제 구현에서는 인스타그램의 내부 API나 웹 스크래핑이 필요합니다.
  /// 여기서는 시뮬레이션으로 구현합니다.
  Future<String?> _extractAudioUrl(String instagramUrl) async {
    try {
      // 실제 구현에서는 다음과 같은 방법들이 필요합니다:
      // 1. 인스타그램 Graph API 사용
      // 2. 웹 스크래핑을 통한 메타데이터 추출
      // 3. 서드파티 API 서비스 사용
      
      // 시뮬레이션: 더미 오디오 URL 반환
      await Future.delayed(const Duration(seconds: 2));
      
      // 실제로는 인스타그램에서 제공하는 오디오 URL을 반환해야 합니다
      // 예: return 'https://instagram.com/audio/example.mp3';
      
      // 개발/테스트용 더미 URL
      return 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
      
    } catch (e) {
      debugPrint('오디오 URL 추출 오류: $e');
      return null;
    }
  }

  /// 오디오 파일 다운로드
  Future<String> _downloadAudio(String audioUrl, String originalUrl) async {
    try {
      // 파일명 생성
      String fileName = _generateFileName(originalUrl);
      
      // 다운로드 디렉토리 가져오기
      Directory appDir = await getApplicationDocumentsDirectory();
      String audioDir = path.join(appDir.path, 'audio_files');
      
      // 디렉토리 생성
      Directory(audioDir).createSync(recursive: true);
      
      // 파일 경로
      String filePath = path.join(audioDir, fileName);
      
      // 다운로드
      await _dio.download(audioUrl, filePath);
      
      return filePath;
      
    } catch (e) {
      debugPrint('오디오 다운로드 오류: $e');
      rethrow;
    }
  }

  /// 파일명 생성
  String _generateFileName(String instagramUrl) {
    DateTime now = DateTime.now();
    String timestamp = now.millisecondsSinceEpoch.toString();
    
    // URL에서 고유 식별자 추출 시도
    String? reelId = _extractReelId(instagramUrl);
    String identifier = reelId ?? timestamp;
    
    return 'instagram_reel_${identifier}.wav';
  }

  /// 릴스 ID 추출
  String? _extractReelId(String url) {
    try {
      // URL에서 릴스 ID 추출
      RegExp regex = RegExp(r'/reel/([^/?]+)');
      Match? match = regex.firstMatch(url);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  /// 공유된 텍스트에서 인스타그램 URL 추출
  String? extractInstagramUrlFromText(String text) {
    try {
      // 인스타그램 URL 패턴 찾기
      RegExp regex = RegExp(
        r'https?://(?:www\.)?instagram\.com/(?:reel|reels)/([^/\s]+)',
        caseSensitive: false,
      );
      
      Match? match = regex.firstMatch(text);
      return match?.group(0);
    } catch (e) {
      debugPrint('URL 추출 오류: $e');
      return null;
    }
  }

  /// URL이 인스타그램 릴스인지 확인
  bool isInstagramReelsUrl(String url) {
    return _isValidInstagramUrl(url) && _isReelsUrl(url);
  }

  /// 릴스 메타데이터 추출 (제목, 설명 등)
  Future<Map<String, dynamic>> extractReelMetadata(String instagramUrl) async {
    try {
      // 실제 구현에서는 인스타그램 API를 통해 메타데이터를 가져와야 합니다.
      // 현재는 더미 데이터를 반환합니다.
      final reelId = _extractReelId(instagramUrl);
      
      return {
        'id': reelId,
        'title': 'Instagram Reel $reelId',
        'description': '인스타그램에서 공유된 릴스입니다.',
        'thumbnailUrl': null,
        'duration': const Duration(seconds: 30),
        'createdAt': DateTime.now(),
      };
    } catch (e) {
      debugPrint('릴스 메타데이터 추출 오류: $e');
      return {
        'id': _extractReelId(instagramUrl),
        'title': 'Instagram Reel',
        'description': null,
        'thumbnailUrl': null,
        'duration': const Duration(seconds: 30),
        'createdAt': DateTime.now(),
      };
    }
  }
}
