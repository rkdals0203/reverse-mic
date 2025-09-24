class AudioFileModel {
  final String name;
  final String path;
  final Duration duration;
  final DateTime createdAt;
  final int? sizeInBytes;

  AudioFileModel({
    required this.name,
    required this.path,
    required this.duration,
    required this.createdAt,
    this.sizeInBytes,
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'duration': duration.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
      'sizeInBytes': sizeInBytes,
    };
  }

  // JSON 역직렬화
  factory AudioFileModel.fromJson(Map<String, dynamic> json) {
    return AudioFileModel(
      name: json['name'] as String,
      path: json['path'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sizeInBytes: json['sizeInBytes'] as int?,
    );
  }

  // 파일 크기를 사람이 읽기 쉬운 형태로 변환
  String get formattedSize {
    if (sizeInBytes == null) return '알 수 없음';
    
    final kb = sizeInBytes! / 1024;
    final mb = kb / 1024;
    
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    } else if (kb >= 1) {
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      return '$sizeInBytes Bytes';
    }
  }

  // 재생 시간을 사람이 읽기 쉬운 형태로 변환
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 생성 날짜를 사람이 읽기 쉬운 형태로 변환
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${createdAt.year}년 ${createdAt.month}월 ${createdAt.day}일';
    }
  }

  // 파일 복사본 생성
  AudioFileModel copyWith({
    String? name,
    String? path,
    Duration? duration,
    DateTime? createdAt,
    int? sizeInBytes,
  }) {
    return AudioFileModel(
      name: name ?? this.name,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    );
  }

  @override
  String toString() {
    return 'AudioFileModel(name: $name, path: $path, duration: $duration, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AudioFileModel &&
        other.name == name &&
        other.path == path &&
        other.duration == duration &&
        other.createdAt == createdAt &&
        other.sizeInBytes == sizeInBytes;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        path.hashCode ^
        duration.hashCode ^
        createdAt.hashCode ^
        sizeInBytes.hashCode;
  }
}
