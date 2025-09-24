import 'package:flutter/foundation.dart';

class InstagramReelModel {
  final String id;
  final String originalUrl;
  final String audioFilePath;
  final String title;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final Duration duration;
  final String? description;

  InstagramReelModel({
    required this.id,
    required this.originalUrl,
    required this.audioFilePath,
    required this.title,
    this.thumbnailUrl,
    required this.createdAt,
    required this.duration,
    this.description,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalUrl': originalUrl,
      'audioFilePath': audioFilePath,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
      'duration': duration.inMilliseconds,
      'description': description,
    };
  }

  /// JSON에서 객체 생성
  factory InstagramReelModel.fromJson(Map<String, dynamic> json) {
    return InstagramReelModel(
      id: json['id'],
      originalUrl: json['originalUrl'],
      audioFilePath: json['audioFilePath'],
      title: json['title'],
      thumbnailUrl: json['thumbnailUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      duration: Duration(milliseconds: json['duration']),
      description: json['description'],
    );
  }

  /// 릴스 ID 추출
  static String extractReelId(String url) {
    try {
      RegExp regex = RegExp(r'/reel/([^/?]+)');
      Match? match = regex.firstMatch(url);
      return match?.group(1) ?? DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// 파일명 생성
  String get fileName {
    return 'instagram_reel_${id}.wav';
  }

  /// 표시용 제목 생성
  String get displayTitle {
    if (title.isNotEmpty) return title;
    return 'Instagram Reel $id';
  }

  /// 생성 시간 포맷팅
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  /// 재생 시간 포맷팅
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'InstagramReelModel(id: $id, title: $title, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstagramReelModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
