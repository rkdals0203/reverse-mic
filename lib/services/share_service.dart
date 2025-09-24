import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'instagram_service.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final InstagramService _instagramService = InstagramService();

  /// 공유된 콘텐츠 처리
  Future<String?> handleSharedContent(String sharedText) async {
    try {
      debugPrint('공유된 콘텐츠 처리: $sharedText');
      
      // 인스타그램 URL 추출
      String? instagramUrl = _instagramService.extractInstagramUrlFromText(sharedText);
      
      if (instagramUrl != null) {
        debugPrint('인스타그램 URL 발견: $instagramUrl');
        
        // 릴스 URL인지 확인
        if (_instagramService.isInstagramReelsUrl(instagramUrl)) {
          // 오디오 추출 및 저장
          String? savedPath = await _instagramService.extractAudioFromInstagramUrl(instagramUrl);
          
          if (savedPath != null) {
            debugPrint('인스타그램 릴스 오디오 저장 완료: $savedPath');
            return savedPath;
          }
        } else {
          throw Exception('릴스 URL이 아닙니다. 릴스를 공유해주세요.');
        }
      } else {
        throw Exception('인스타그램 URL을 찾을 수 없습니다.');
      }
      
      return null;
    } catch (e) {
      debugPrint('공유 콘텐츠 처리 오류: $e');
      rethrow;
    }
  }

  /// 클립보드에서 텍스트 가져오기
  Future<String?> getClipboardText() async {
    try {
      ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e) {
      debugPrint('클립보드 읽기 오류: $e');
      return null;
    }
  }

  /// 클립보드 텍스트에서 인스타그램 릴스 처리
  Future<String?> processClipboardForInstagramReels() async {
    try {
      String? clipboardText = await getClipboardText();
      
      if (clipboardText != null && clipboardText.isNotEmpty) {
        return await handleSharedContent(clipboardText);
      }
      
      return null;
    } catch (e) {
      debugPrint('클립보드 처리 오류: $e');
      return null;
    }
  }

  /// URL 유효성 검사
  bool isValidInstagramReelsUrl(String url) {
    return _instagramService.isInstagramReelsUrl(url);
  }

  /// 텍스트에서 인스타그램 URL 추출
  String? extractInstagramUrl(String text) {
    return _instagramService.extractInstagramUrlFromText(text);
  }
}
