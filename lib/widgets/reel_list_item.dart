import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/instagram_reel_model.dart';

class ReelListItem extends StatelessWidget {
  final InstagramReelModel reel;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const ReelListItem({
    super.key,
    required this.reel,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildThumbnail(context),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContent(context),
              ),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 썸네일 위젯
  Widget _buildThumbnail(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Stack(
        children: [
          // 썸네일 이미지 또는 기본 아이콘
          Center(
            child: Icon(
              Icons.video_library,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          // 재생 시간 표시
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                reel.formattedDuration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 선택 표시
          if (isSelectionMode)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  /// 콘텐츠 위젯
  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          reel.displayTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // 설명
        if (reel.description != null && reel.description!.isNotEmpty)
          Text(
            reel.description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        // 메타 정보
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              reel.formattedCreatedAt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.play_circle_outline,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              reel.formattedDuration,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 액션 버튼들
  Widget _buildActions(BuildContext context) {
    if (isSelectionMode) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.play_circle_filled,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: onPlay,
          tooltip: '재생',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'delete':
                onDelete();
                break;
              case 'share':
                // TODO: 공유 기능 구현
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('공유'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
