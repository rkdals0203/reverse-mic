import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'instagram_service.dart';
import 'package:dio/dio.dart';
import '../models/instagram_reel_model.dart';

class AppShareHandler {
  static final AppShareHandler _instance = AppShareHandler._internal();
  factory AppShareHandler() => _instance;
  AppShareHandler._internal();

  final InstagramService _instagramService = InstagramService();
  final Dio _dio = Dio();

  /// 앱이 공유받은 데이터로 시작되었는지 확인하고 처리
  Future<String?> handleInitialSharedData() async {
    try {
      debugPrint('초기 공유 데이터 처리 시작');
      
      // Android에서 Intent 데이터 처리
      if (Platform.isAndroid) {
        return await _handleAndroidIntent();
      }
      // iOS에서 URL Scheme 처리
      else if (Platform.isIOS) {
        return await _handleIOSUrlScheme();
      }
      
      return null;
    } catch (e) {
      debugPrint('초기 공유 데이터 처리 오류: $e');
      return null;
    }
  }

  /// Android Intent 데이터 처리
  Future<String?> _handleAndroidIntent() async {
    try {
      // Flutter에서 Android Intent 데이터를 받기 위해 MethodChannel 사용
      const platform = MethodChannel('com.example.reverse_mic/share');
      
      // Intent에서 텍스트 데이터 가져오기
      final String? sharedText = await platform.invokeMethod('getSharedText');
      
      if (sharedText != null && sharedText.isNotEmpty) {
        debugPrint('Android에서 공유받은 텍스트: $sharedText');
        return await _processSharedText(sharedText);
      }
      
      return null;
    } catch (e) {
      debugPrint('Android Intent 처리 오류: $e');
      return null;
    }
  }

  /// iOS URL Scheme 처리
  Future<String?> _handleIOSUrlScheme() async {
    try {
      // Flutter에서 iOS URL Scheme을 받기 위해 MethodChannel 사용
      const platform = MethodChannel('com.example.reverse_mic/share');
      
      // URL Scheme에서 데이터 가져오기
      final String? sharedUrl = await platform.invokeMethod('getSharedUrl');
      
      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        debugPrint('iOS에서 공유받은 URL: $sharedUrl');
        return await _processSharedText(sharedUrl);
      }
      
      return null;
    } catch (e) {
      debugPrint('iOS URL Scheme 처리 오류: $e');
      return null;
    }
  }

  /// 공유받은 텍스트 처리
  Future<String?> _processSharedText(String sharedText) async {
    try {
      // 인스타그램 URL 추출
      String? instagramUrl = _instagramService.extractInstagramUrlFromText(sharedText);
      
      if (instagramUrl != null && _instagramService.isInstagramReelsUrl(instagramUrl)) {
        debugPrint('인스타그램 릴스 URL 발견: $instagramUrl');
        
        // 오디오 추출 및 저장
        String? savedPath = await _instagramService.extractAudioFromInstagramUrl(instagramUrl);
        
        if (savedPath != null) {
          debugPrint('릴스 오디오 저장 완료: $savedPath');
          
          // 릴스 메타데이터 추출
          final metadata = await _instagramService.extractReelMetadata(instagramUrl);
          
          // InstagramReelsProvider에 릴스 추가
          // 이 부분은 실제 앱에서는 Provider를 통해 처리해야 합니다.
          debugPrint('릴스 메타데이터: $metadata');
          
          return savedPath;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('공유 텍스트 처리 오류: $e');
      return null;
    }
  }

  /// 앱이 실행 중일 때 공유받은 데이터 처리
  Future<String?> handleRuntimeSharedData(String sharedText) async {
    try {
      debugPrint('런타임 공유 데이터 처리: $sharedText');
      return await _processSharedText(sharedText);
    } catch (e) {
      debugPrint('런타임 공유 데이터 처리 오류: $e');
      return null;
    }
  }

  /// 인스타그램 릴스 URL인지 확인
  bool isInstagramReelsUrl(String url) {
    return _instagramService.isInstagramReelsUrl(url);
  }

  /// 텍스트에서 인스타그램 URL 추출
  String? extractInstagramUrl(String text) {
    return _instagramService.extractInstagramUrlFromText(text);
  }
}
