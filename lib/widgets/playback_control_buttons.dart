import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class PlaybackControlButtons extends StatelessWidget {
  final double buttonSize;
  final double spacing;

  const PlaybackControlButtons({
    super.key,
    this.buttonSize = 80,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // 웨이브폼 위젯과 동일한 너비 사용
            final availableWidth = constraints.maxWidth;
            final buttonWidth = (availableWidth - spacing) / 2;
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 역재생 버튼
                SizedBox(
                  width: buttonWidth,
                  child: _buildReverseButton(context, audioProvider),
                ),
                
                // 재생/일시정지 버튼
                SizedBox(
                  width: buttonWidth,
                  child: _buildPlayPauseButton(context, audioProvider),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 역재생 버튼
  Widget _buildReverseButton(BuildContext context, AudioProvider audioProvider) {
    final isReversed = audioProvider.isReversed;
    
    return _buildControlButton(
      context: context,
      icon: Icons.fast_rewind,
      label: '역재생',
      isActive: isReversed,
      onPressed: () => _toggleReverse(audioProvider),
      tooltip: isReversed ? '역재생 해제' : '역재생 시작',
    );
  }

  /// 재생/일시정지 버튼
  Widget _buildPlayPauseButton(BuildContext context, AudioProvider audioProvider) {
    final isPlaying = audioProvider.isPlaying;
    final hasAudio = audioProvider.currentAudioFile != null;
    
    return _buildControlButton(
      context: context,
      icon: isPlaying ? Icons.pause : Icons.play_arrow,
      label: isPlaying ? '일시정지' : '재생',
      isActive: isPlaying,
      onPressed: hasAudio ? () => _togglePlayPause(audioProvider) : null,
      tooltip: hasAudio 
          ? (isPlaying ? '일시정지' : '재생')
          : '재생할 오디오가 없습니다',
      isPrimary: true,
    );
  }


  /// 컨트롤 버튼 빌더
  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 버튼 색상 결정
    Color buttonColor;
    Color iconColor;
    Color borderColor;
    
    if (onPressed == null) {
      // 비활성화 상태
      buttonColor = colorScheme.surfaceVariant.withValues(alpha: 0.5);
      iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
      borderColor = colorScheme.outline.withValues(alpha: 0.3);
    } else if (isActive) {
      // 활성화 상태
      buttonColor = isPrimary 
          ? colorScheme.primary
          : colorScheme.primaryContainer;
      iconColor = isPrimary 
          ? colorScheme.onPrimary
          : colorScheme.onPrimaryContainer;
      borderColor = colorScheme.primary;
    } else {
      // 기본 상태
      buttonColor = colorScheme.surfaceVariant.withValues(alpha: 0.4);
      iconColor = colorScheme.onSurfaceVariant;
      borderColor = colorScheme.outline.withValues(alpha: 0.2);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 반응형 크기 계산
        final containerWidth = constraints.maxWidth;
        final containerHeight = buttonSize;
        final iconSize = containerWidth * 0.3; // 컨테이너 너비의 30%
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: containerWidth,
              height: containerHeight,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ] : [
                  BoxShadow(
                    color: colorScheme.background.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onPressed,
                  child: Center(
                    child: Icon(
                      icon,
                      size: iconSize.clamp(24.0, 48.0), // 최소 24, 최대 48
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onPressed == null 
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  /// 역재생 토글
  void _toggleReverse(AudioProvider audioProvider) {
    if (audioProvider.isReversed) {
      audioProvider.setReverse(false);
    } else {
      audioProvider.setReverse(true);
      // 역재생 모드로 전환 시 자동 재생
      if (audioProvider.currentAudioFile != null && !audioProvider.isPlaying) {
        audioProvider.play();
      }
    }
  }

  /// 재생/일시정지 토글
  void _togglePlayPause(AudioProvider audioProvider) {
    if (audioProvider.isPlaying) {
      audioProvider.pause();
    } else {
      audioProvider.play();
    }
  }

}
