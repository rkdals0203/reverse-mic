import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/audio_file_model.dart';

enum SortOrder { dateNewest, dateOldest, nameAZ, nameZA, duration }

class FileManagerProvider extends ChangeNotifier {
  List<AudioFileModel> _savedFiles = [];
  SortOrder _sortOrder = SortOrder.dateNewest;
  String _searchQuery = '';
  bool _isLoading = false;

  // Getters
  List<AudioFileModel> get savedFiles => _getFilteredAndSortedFiles();
  SortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // 필터링 및 정렬된 파일 목록 반환
  List<AudioFileModel> _getFilteredAndSortedFiles() {
    List<AudioFileModel> filtered = _savedFiles;

    // 검색 필터링
    if (_searchQuery.isNotEmpty) {
      filtered = _savedFiles.where((file) {
        return file.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 정렬
    switch (_sortOrder) {
      case SortOrder.dateNewest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOrder.dateOldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOrder.nameAZ:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOrder.nameZA:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOrder.duration:
        filtered.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }

    return filtered;
  }

  // 앱 시작 시 저장된 파일들 로드
  Future<void> loadSavedFiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${directory.path}/saved');
      
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      // 메타데이터 파일 로드
      await _loadFileMetadata();
      
      // 실제 파일 존재 여부 확인 및 정리
      await _validateFiles();
      
    } catch (e) {
      debugPrint('파일 로드 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 파일 메타데이터 로드
  Future<void> _loadFileMetadata() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final metadataFile = File('${directory.path}/file_metadata.json');
      
      if (await metadataFile.exists()) {
        final jsonString = await metadataFile.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        
        _savedFiles = jsonList
            .map((json) => AudioFileModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('메타데이터 로드 오류: $e');
      _savedFiles = [];
    }
  }

  // 파일 유효성 검사
  Future<void> _validateFiles() async {
    final validFiles = <AudioFileModel>[];
    
    for (final audioFile in _savedFiles) {
      final file = File(audioFile.path);
      if (await file.exists()) {
        // 파일 크기 정보 업데이트
        final stat = await file.stat();
        final updatedFile = audioFile.copyWith(sizeInBytes: stat.size);
        validFiles.add(updatedFile);
      }
    }
    
    _savedFiles = validFiles;
    await _saveFileMetadata();
  }

  // 파일 메타데이터 저장
  Future<void> _saveFileMetadata() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final metadataFile = File('${directory.path}/file_metadata.json');
      
      final jsonList = _savedFiles.map((file) => file.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await metadataFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint('메타데이터 저장 오류: $e');
    }
  }

  // 새 파일 추가
  Future<bool> addFile(AudioFileModel audioFile) async {
    try {
      _savedFiles.add(audioFile);
      await _saveFileMetadata();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('파일 추가 오류: $e');
      return false;
    }
  }

  // 파일 이름 변경
  Future<bool> renameFile(AudioFileModel audioFile, String newName) async {
    try {
      final index = _savedFiles.indexOf(audioFile);
      if (index == -1) return false;

      final updatedFile = audioFile.copyWith(name: newName);
      _savedFiles[index] = updatedFile;
      
      await _saveFileMetadata();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('파일 이름 변경 오류: $e');
      return false;
    }
  }

  // 파일 삭제
  Future<bool> deleteFile(AudioFileModel audioFile) async {
    try {
      // 실제 파일 삭제
      final file = File(audioFile.path);
      if (await file.exists()) {
        await file.delete();
      }

      // 목록에서 제거
      _savedFiles.remove(audioFile);
      
      await _saveFileMetadata();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('파일 삭제 오류: $e');
      return false;
    }
  }

  // 여러 파일 삭제
  Future<int> deleteFiles(List<AudioFileModel> filesToDelete) async {
    int deletedCount = 0;
    
    for (final audioFile in filesToDelete) {
      if (await deleteFile(audioFile)) {
        deletedCount++;
      }
    }
    
    return deletedCount;
  }

  // 파일 공유
  Future<void> shareFile(AudioFileModel audioFile) async {
    try {
      final file = File(audioFile.path);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(audioFile.path)],
          text: '${audioFile.name} - Reverse Mic으로 만든 오디오 파일',
        );
      }
    } catch (e) {
      debugPrint('파일 공유 오류: $e');
    }
  }

  // 여러 파일 공유
  Future<void> shareFiles(List<AudioFileModel> filesToShare) async {
    try {
      final existingFiles = <XFile>[];
      
      for (final audioFile in filesToShare) {
        final file = File(audioFile.path);
        if (await file.exists()) {
          existingFiles.add(XFile(audioFile.path));
        }
      }
      
      if (existingFiles.isNotEmpty) {
        await Share.shareXFiles(
          existingFiles,
          text: 'Reverse Mic으로 만든 오디오 파일들',
        );
      }
    } catch (e) {
      debugPrint('파일들 공유 오류: $e');
    }
  }

  // 정렬 순서 변경
  void setSortOrder(SortOrder newOrder) {
    _sortOrder = newOrder;
    notifyListeners();
  }

  // 검색어 설정
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // 검색어 초기화
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // 저장 공간 사용량 계산
  int get totalStorageUsed {
    return _savedFiles.fold<int>(
      0, 
      (sum, file) => sum + (file.sizeInBytes ?? 0),
    );
  }

  // 사용량을 사람이 읽기 쉬운 형태로 변환
  String get formattedStorageUsed {
    final bytes = totalStorageUsed;
    final kb = bytes / 1024;
    final mb = kb / 1024;
    
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    } else if (kb >= 1) {
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      return '$bytes Bytes';
    }
  }

  // 파일 개수
  int get fileCount => _savedFiles.length;

  // 총 재생 시간
  Duration get totalDuration {
    return _savedFiles.fold<Duration>(
      Duration.zero,
      (total, file) => total + file.duration,
    );
  }

  // 총 재생 시간을 사람이 읽기 쉬운 형태로 변환
  String get formattedTotalDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}시간 ${minutes}분 ${seconds}초';
    } else if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }
}
