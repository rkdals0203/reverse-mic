import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final audioFile = audioProvider.currentAudioFile;
        if (audioFile == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 파일 정보
                Row(
                  children: [
                    const Icon(Icons.audiotrack, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audioFile.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            audioFile.formattedDuration,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 진행 바
                _buildProgressBar(context, audioProvider),
                
                const SizedBox(height: 16),
                
                // 재생 컨트롤
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 정방향 재생
                    _buildControlButton(
                      context,
                      icon: audioProvider.playbackState == PlaybackState.playing && !audioProvider.isReversed
                          ? Icons.pause
                          : Icons.play_arrow,
                      label: '정방향',
                      onPressed: () => _handlePlayback(audioProvider, false),
                      isActive: audioProvider.playbackState == PlaybackState.playing && !audioProvider.isReversed,
                    ),
                    
                    // 역방향 재생
                    _buildControlButton(
                      context,
                      icon: audioProvider.playbackState == PlaybackState.playing && audioProvider.isReversed
                          ? Icons.pause
                          : Icons.play_arrow_outlined,
                      label: '역방향',
                      onPressed: () => _handlePlayback(audioProvider, true),
                      isActive: audioProvider.playbackState == PlaybackState.playing && audioProvider.isReversed,
                      iconRotation: 180,
                    ),
                    
                    // 정지
                    _buildControlButton(
                      context,
                      icon: Icons.stop,
                      label: '정지',
                      onPressed: audioProvider.playbackState != PlaybackState.idle
                          ? () => audioProvider.stopAudio()
                          : null,
                      isActive: false,
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 현재 설정 표시
                if (audioProvider.playbackSpeed != 1.0 || 
                    audioProvider.pitch != 0.0 || 
                    audioProvider.echoEnabled || 
                    audioProvider.reverbEnabled)
                  _buildCurrentSettings(context, audioProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioProvider audioProvider) {
    final progress = audioProvider.totalDuration.inMilliseconds > 0
        ? audioProvider.playbackPosition.inMilliseconds / audioProvider.totalDuration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 4,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              // TODO: 시크 기능 구현
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(audioProvider.playbackPosition),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                _formatDuration(audioProvider.totalDuration),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isActive,
    double iconRotation = 0,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: IconButton(
            icon: Transform.rotate(
              angle: iconRotation * 3.14159 / 180,
              child: Icon(icon),
            ),
            onPressed: onPressed,
            color: isActive ? Colors.white : null,
            iconSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null ? null : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSettings(BuildContext context, AudioProvider audioProvider) {
    final settings = <String>[];
    
    if (audioProvider.playbackSpeed != 1.0) {
      settings.add('속도: ${audioProvider.playbackSpeed.toStringAsFixed(1)}x');
    }
    
    if (audioProvider.pitch != 0.0) {
      final pitchText = audioProvider.pitch > 0 ? '+${audioProvider.pitch.toStringAsFixed(1)}' : audioProvider.pitch.toStringAsFixed(1);
      settings.add('피치: ${pitchText}반음');
    }
    
    if (audioProvider.echoEnabled) {
      settings.add('에코');
    }
    
    if (audioProvider.reverbEnabled) {
      settings.add('리버브');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        settings.join(' • '),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handlePlayback(AudioProvider audioProvider, bool isReversed) {
    if (audioProvider.playbackState == PlaybackState.playing) {
      if (audioProvider.isReversed == isReversed) {
        // 같은 방향으로 재생 중이면 일시정지
        audioProvider.pauseAudio();
      } else {
        // 다른 방향으로 재생 중이면 정지 후 새로 재생
        audioProvider.stopAudio().then((_) {
          if (isReversed) {
            audioProvider.playReversedAudio();
          } else {
            audioProvider.playAudio();
          }
        });
      }
    } else {
      // 정지 상태이면 재생 시작
      if (isReversed) {
        audioProvider.playReversedAudio();
      } else {
        audioProvider.playAudio();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
