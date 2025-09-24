import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioControlsWidget extends StatelessWidget {
  const AudioControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오디오 효과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 속도 조절
                _buildSpeedControl(context, audioProvider),
                
                const SizedBox(height: 16),
                
                // 피치 조절
                _buildPitchControl(context, audioProvider),
                
                const SizedBox(height: 16),
                
                // 효과 토글
                _buildEffectsToggle(context, audioProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedControl(BuildContext context, AudioProvider audioProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '재생 속도',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${audioProvider.playbackSpeed.toStringAsFixed(1)}x',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 6,
          ),
          child: Slider(
            value: audioProvider.playbackSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) {
              audioProvider.setPlaybackSpeed(value);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.5x', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('2.0x', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildPitchControl(BuildContext context, AudioProvider audioProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '피치 조절',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${audioProvider.pitch >= 0 ? '+' : ''}${audioProvider.pitch.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 6,
          ),
          child: Slider(
            value: audioProvider.pitch,
            min: -12.0,
            max: 12.0,
            divisions: 24,
            onChanged: (value) {
              audioProvider.setPitch(value);
            },
            activeColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-12', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('+12', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildEffectsToggle(BuildContext context, AudioProvider audioProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오디오 효과',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEffectToggleCard(
                title: '에코',
                description: '울림 효과',
                icon: Icons.graphic_eq,
                isEnabled: audioProvider.echoEnabled,
                onToggle: () => audioProvider.toggleEcho(),
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEffectToggleCard(
                title: '리버브',
                description: '공간감 효과',
                icon: Icons.surround_sound,
                isEnabled: audioProvider.reverbEnabled,
                onToggle: () => audioProvider.toggleReverb(),
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEffectToggleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onToggle,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isEnabled ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isEnabled ? color : Colors.grey,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? color.withValues(alpha: 0.8) : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isEnabled ? color : Colors.grey.withValues(alpha: 0.3),
              ),
              child: AnimatedAlign(
                alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
