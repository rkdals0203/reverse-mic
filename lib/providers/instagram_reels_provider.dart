import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/instagram_reel_model.dart';

class InstagramReelsProvider extends ChangeNotifier {
  List<InstagramReelModel> _reels = [];
  bool _isLoading = false;
  String? _error;

  List<InstagramReelModel> get reels => List.unmodifiable(_reels);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 릴스 목록 로드
  Future<void> loadReels() async {
    try {
      _setLoading(true);
      _clearError();

      final reelsData = await _loadReelsFromStorage();
      _reels = reelsData;
      
      notifyListeners();
    } catch (e) {
      _setError('릴스 목록을 불러오는데 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 새 릴스 추가
  Future<void> addReel({
    required String originalUrl,
    required String audioFilePath,
    String? title,
    String? thumbnailUrl,
    Duration? duration,
    String? description,
  }) async {
    try {
      final reelId = InstagramReelModel.extractReelId(originalUrl);
      
      final newReel = InstagramReelModel(
        id: reelId,
        originalUrl: originalUrl,
        audioFilePath: audioFilePath,
        title: title ?? 'Instagram Reel',
        thumbnailUrl: thumbnailUrl,
        createdAt: DateTime.now(),
        duration: duration ?? const Duration(seconds: 30),
        description: description,
      );

      _reels.insert(0, newReel); // 최신 순으로 정렬
      await _saveReelsToStorage();
      
      notifyListeners();
    } catch (e) {
      _setError('릴스 추가에 실패했습니다: $e');
    }
  }

  /// 릴스 삭제
  Future<void> deleteReel(String reelId) async {
    try {
      final reelIndex = _reels.indexWhere((reel) => reel.id == reelId);
      if (reelIndex == -1) return;

      final reel = _reels[reelIndex];
      
      // 오디오 파일 삭제
      final audioFile = File(reel.audioFilePath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      _reels.removeAt(reelIndex);
      await _saveReelsToStorage();
      
      notifyListeners();
    } catch (e) {
      _setError('릴스 삭제에 실패했습니다: $e');
    }
  }

  /// 여러 릴스 삭제
  Future<void> deleteMultipleReels(List<String> reelIds) async {
    try {
      for (final reelId in reelIds) {
        await deleteReel(reelId);
      }
    } catch (e) {
      _setError('릴스 삭제에 실패했습니다: $e');
    }
  }

  /// 릴스 검색
  List<InstagramReelModel> searchReels(String query) {
    if (query.isEmpty) return _reels;
    
    return _reels.where((reel) {
      return reel.title.toLowerCase().contains(query.toLowerCase()) ||
             reel.description?.toLowerCase().contains(query.toLowerCase()) == true ||
             reel.originalUrl.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// 릴스 정렬
  void sortReels(ReelSortType sortType) {
    switch (sortType) {
      case ReelSortType.newest:
        _reels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ReelSortType.oldest:
        _reels.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ReelSortType.title:
        _reels.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ReelSortType.duration:
        _reels.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    notifyListeners();
  }

  /// 특정 릴스 찾기
  InstagramReelModel? findReelById(String reelId) {
    try {
      return _reels.firstWhere((reel) => reel.id == reelId);
    } catch (e) {
      return null;
    }
  }

  /// 저장소에서 릴스 데이터 로드
  Future<List<InstagramReelModel>> _loadReelsFromStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reelsFile = File(path.join(directory.path, 'instagram_reels.json'));
      
      if (!await reelsFile.exists()) {
        return [];
      }

      final jsonString = await reelsFile.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) => InstagramReelModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('릴스 데이터 로드 오류: $e');
      return [];
    }
  }

  /// 저장소에 릴스 데이터 저장
  Future<void> _saveReelsToStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reelsFile = File(path.join(directory.path, 'instagram_reels.json'));
      
      final jsonList = _reels.map((reel) => reel.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await reelsFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint('릴스 데이터 저장 오류: $e');
      throw e;
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 에러 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 에러 초기화
  void _clearError() {
    _error = null;
  }

  /// 전체 릴스 개수
  int get totalCount => _reels.length;

  /// 총 재생 시간
  Duration get totalDuration {
    return _reels.fold(
      Duration.zero,
      (total, reel) => total + reel.duration,
    );
  }
}

/// 릴스 정렬 타입
enum ReelSortType {
  newest,
  oldest,
  title,
  duration,
}
